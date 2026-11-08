"""CPU/GPU core-count, clock limits, and hardware topology detection for the BC-250.

Split out of the telemetry daemon on purpose: unlike temperature/clock/power,
this is topology and target config info that only changes when someone actively
unlocks more cores/CUs (a reboot for CPU cores, or a live WGP toggle for GPU CUs)
or changes overclock/governor targets ? it doesn't need the daemon's 700ms polling
cadence, and living here means checking it doesn't require rebuilding and reinstalling
the C++ binary.
"""

import configparser
import ctypes
import os
import platform
import re
import subprocess

try:
    import tomllib
except ImportError:
    tomllib = None

# AMDGPU_INFO_DEV_INFO ? same query bc250-toolkit and bc250-cu-live-manager
# use (via the same libdrm_amdgpu.so.1 call), fills a struct
# drm_amdgpu_info_device. cu_active_number sits at byte offset 48 in that
# struct ? cross-checked against bc250-cu-live-manager, which reads the
# cu_bitmap array starting right after it, at offset 56.
_AMDGPU_INFO_DEV_INFO = 0x16
_CU_ACTIVE_NUMBER_OFFSET = 48
_QUERY_BUF_SIZE = 256

_CU_LIVE_MANAGER_CONF = '/etc/bc250-cu-live-manager.conf'
_CU_LIVE_MANAGER_SERVICE = 'bc250-cu-live-manager.service'

CPU_OC_CONF = '/etc/bc250-smu-oc.conf'
GPU_GOV_CONF = '/etc/cyan-skillfish-governor-smu/config.toml'


def _service_active(name):
    try:
        result = subprocess.run(
            ['systemctl', 'is-active', name],
            capture_output=True, text=True, timeout=2,
        )
        return result.stdout.strip() == 'active'
    except (OSError, subprocess.SubprocessError):
        return False


def _read_cu_live_manager_masks():
    """BC250_WGP_MASKS=SE0.SH0,SE0.SH1,SE1.SH0,SE1.SH1 ? each a 5-bit WGP
    dispatch mask (bit per WGP, 2 CU per WGP), same encoding
    bc250-cu-live-manager itself uses for its "CUs active & routed" total."""
    try:
        with open(_CU_LIVE_MANAGER_CONF) as f:
            text = f.read()
    except OSError:
        return None
    match = re.search(r'^BC250_WGP_MASKS=(.+)$', text, re.MULTILINE)
    if not match:
        return None
    try:
        masks = [int(v.strip(), 0) for v in match.group(1).split(',')]
    except ValueError:
        return None
    if not masks:
        return None
    return sum(bin(mask & 0x1f).count('1') * 2 for mask in masks)


def read_cpu_physical_cores():
    """Physical core count, straight from cpuinfo's own "cpu cores" field ?
    not threads/2, since a core disabled by binning isn't guaranteed to
    leave exactly half the threads intact. Stock BC-250 boards are 6 cores;
    unlocked boards are 8 cores."""
    core_ids = set()
    cpu_cores_val = None
    try:
        with open('/proc/cpuinfo') as f:
            for line in f:
                if line.startswith('cpu cores') and cpu_cores_val is None:
                    cpu_cores_val = int(line.split(':', 1)[1].strip())
                elif line.startswith('core id'):
                    core_ids.add(line.split(':', 1)[1].strip())
        if cpu_cores_val and cpu_cores_val > 0:
            return cpu_cores_val
        if core_ids:
            return len(core_ids)
    except (OSError, ValueError):
        pass
    threads = read_cpu_threads()
    if threads:
        return 8 if threads >= 16 else 6
    return 8


def _open_render_node():
    dri = '/dev/dri'
    if not os.path.isdir(dri):
        return -1
    for name in sorted(os.listdir(dri)):
        if name.startswith('renderD'):
            try:
                return os.open(os.path.join(dri, name), os.O_RDWR)
            except OSError:
                continue
    return -1


def _read_driver_cu_active():
    """Active Compute Unit count per the amdgpu kernel driver's own cached
    topology ? correct for a boot-time unlock (e.g. a kernel patch clearing
    the harvest mask before CU enumeration runs), but stale for anything
    that changes dispatch registers live, after the driver already cached
    this number."""
    try:
        libdrm = ctypes.CDLL('libdrm_amdgpu.so.1')
    except OSError:
        return None

    fd = _open_render_node()
    if fd < 0:
        return None

    dev = ctypes.c_void_p()
    try:
        major, minor = ctypes.c_uint32(), ctypes.c_uint32()
        rc = libdrm.amdgpu_device_initialize(fd, ctypes.byref(major), ctypes.byref(minor), ctypes.byref(dev))
        if rc != 0:
            return None

        buf = (ctypes.c_uint8 * _QUERY_BUF_SIZE)()
        rc = libdrm.amdgpu_query_info(dev, _AMDGPU_INFO_DEV_INFO, len(buf), ctypes.byref(buf))
        if rc != 0:
            return None

        cu_active = int.from_bytes(bytes(buf[_CU_ACTIVE_NUMBER_OFFSET:_CU_ACTIVE_NUMBER_OFFSET + 4]), 'little')
        return cu_active if cu_active > 0 else None
    finally:
        if dev.value:
            libdrm.amdgpu_device_deinitialize(dev)
        os.close(fd)


def read_gpu_cu_active():
    """Active Compute Units for Oberon RDNA2. Factory standard baseline is 24 CUs,
    with unlock tiers at 32, 34, 36, 38, and 40 CUs."""
    if _service_active(_CU_LIVE_MANAGER_SERVICE):
        live_manager_count = _read_cu_live_manager_masks()
        if live_manager_count:
            return live_manager_count
    driver_cu = _read_driver_cu_active()
    if driver_cu and driver_cu > 0:
        return driver_cu
    return 24


def read_cpu_threads():
    """Total logical threads from /proc/cpuinfo (12 on stock 6c, 16 on 8c)."""
    try:
        with open('/proc/cpuinfo') as f:
            count = sum(1 for line in f if line.startswith('processor'))
            if count > 0:
                return count
    except (OSError, ValueError):
        pass
    return os.cpu_count() or 16


def read_cpu_max_mhz(cpu_cores=None):
    """Dynamic CPU frequency target in MHz.
    1. Checks /etc/bc250-smu-oc.conf (target_freq_mhz)
    2. Checks Linux cpufreq scaling_max_freq / cpuinfo_max_freq
    3. Falls back to stock 3200 MHz (or 3500 MHz for 8-core profiles)."""
    parser = configparser.ConfigParser()
    try:
        if parser.read(CPU_OC_CONF):
            freq = parser.getint('overclock', 'frequency', fallback=None)
            if freq and freq > 0:
                return freq
    except (OSError, configparser.Error, ValueError):
        pass

    for p in ('/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq',
              '/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq'):
        try:
            with open(p) as f:
                khz = int(f.read().strip())
                if khz > 0:
                    return round(khz / 1000)
        except (OSError, ValueError):
            pass

    return 3500 if (cpu_cores and cpu_cores >= 8) else 3200


def read_cpu_max_temp_c():
    """Dynamic thermal ceiling in ?C from SMU OC config (fallback 80?C)."""
    parser = configparser.ConfigParser()
    try:
        if parser.read(CPU_OC_CONF):
            temp = parser.getint('overclock', 'max_temperature', fallback=None)
            if temp and temp > 0:
                return temp
    except (OSError, configparser.Error, ValueError):
        pass
    return 80


def read_gpu_target_freq_mhz():
    """Dynamic GPU frequency range (max_mhz, min_mhz).
    Reads /etc/cyan-skillfish-governor-smu/config.toml, falls back to (1850, 500)."""
    max_freq = None
    min_freq = None
    if tomllib is not None:
        try:
            with open(GPU_GOV_CONF, 'rb') as f:
                data = tomllib.load(f)
            freq_range = data.get('frequency-range', {})
            max_freq = freq_range.get('max') or None
            min_freq = freq_range.get('min') or None
        except (OSError, tomllib.TOMLDecodeError):
            pass
    if max_freq is None or min_freq is None:
        try:
            with open(GPU_GOV_CONF, 'r', encoding='utf-8') as f:
                content = f.read()
            m_max = re.search(r'max\s*=\s*(\d+)', content)
            m_min = re.search(r'min\s*=\s*(\d+)', content)
            if m_max: max_freq = int(m_max.group(1))
            if m_min: min_freq = int(m_min.group(1))
        except (OSError, ValueError):
            pass
    return (max_freq or 1850, min_freq or 500)


def read_memory_total_gb():
    """Dynamic memory capacity in GB. Stock BC-250 has 16GB GDDR6 unified across 8 chips."""
    try:
        with open('/proc/meminfo') as f:
            for line in f:
                if line.startswith('MemTotal:'):
                    kb = int(line.split(':', 1)[1].strip().split()[0])
                    gib = kb / (1024 * 1024)
                    if 12 <= gib <= 17:
                        return 16
                    return round(gib)
    except (OSError, ValueError):
        pass
    return 16


def read_topology():
    cpu_cores = read_cpu_physical_cores()
    cpu_threads = read_cpu_threads()
    gpu_cu = read_gpu_cu_active()
    gpu_shaders = (gpu_cu * 64) if gpu_cu else 2560
    cpu_max_mhz = read_cpu_max_mhz(cpu_cores)
    cpu_max_temp = read_cpu_max_temp_c()
    gpu_max_mhz, gpu_min_mhz = read_gpu_target_freq_mhz()
    memory_gb = read_memory_total_gb()

    return {
        'cpu_physical_cores': cpu_cores,
        'cpu_logical_cores': cpu_threads,
        'cpu_max_mhz': cpu_max_mhz,
        'cpu_max_temp_c': cpu_max_temp,
        'gpu_cu_active': gpu_cu,
        'gpu_shaders': gpu_shaders,
        'gpu_max_mhz': gpu_max_mhz,
        'gpu_min_mhz': gpu_min_mhz,
        'memory_total_gb': memory_gb,
        'kernel_release': platform.release(),
    }


if __name__ == '__main__':
    print(read_topology())
