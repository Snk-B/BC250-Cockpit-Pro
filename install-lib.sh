#!/bin/bash

# modinfo/modprobe live in /usr/sbin on Debian/Ubuntu, which is not in a
# regular user's PATH there.
case ":$PATH:" in *:/usr/sbin:*) ;; *) PATH="$PATH:/usr/sbin:/sbin" ;; esac

DASHBOARD_FLAG=""
MEMORY_TEMP_FLAG=auto
MEMORY_MODE_FLAG=detect
COMPONENTS_FLAG=""
DRY_RUN_FLAG=0




# Colors fallback if not set by caller (prevents set -u unbound variable)
GREEN="${GREEN:-[0;32m}"
BLUE="${BLUE:-[0;34m}"
YELLOW="${YELLOW:-[1;33m}"
RED="${RED:-[0;31m}"
NC="${NC:-[0m}"
CYAN="${CYAN:-[0;36m}"
BOLD="${BOLD:-[1m}"
DIM="${DIM:-[2m}"

FIX_GOVERNOR_FLAG=0

# Returns 0 if config has no known conflicts, or 1 if dangerous settings found.
check_governor_smu_config() {
    local conf="${1:-/etc/cyan-skillfish-governor-smu/config.toml}"
    [ -f "$conf" ] || return 0

    local bad=0
    # 1. set-method = "smu"
    if grep -Eiq '^[[:space:]]*set-method[[:space:]]*=[[:space:]]*"?smu"?' "$conf"; then
        bad=1
    fi
    # 2. fix-metrics = true
    if grep -Eiq '^[[:space:]]*fix-metrics[[:space:]]*=[[:space:]]*true' "$conf"; then
        bad=1
    fi
    return "$bad"
}

# Audit governor configuration and print clear warnings or offer to patch
audit_governor_config() {
    local conf="${1:-/etc/cyan-skillfish-governor-smu/config.toml}"
    if [ ! -f "$conf" ]; then
        echo -e "  ${DIM}No cyan-skillfish-governor-smu config found at $conf (skipped)${NC}"
        return 0
    fi

    local bad_set_method=0
    local bad_fix_metrics=0
    local bad_temp_read=0
    local has_issue=0

    if grep -Eiq '^[[:space:]]*set-method[[:space:]]*=[[:space:]]*"?smu"?' "$conf"; then
        bad_set_method=1
        has_issue=1
    fi
    if grep -Eiq '^[[:space:]]*fix-metrics[[:space:]]*=[[:space:]]*true' "$conf"; then
        bad_fix_metrics=1
        has_issue=1
    fi
    if grep -Eiq '^[[:space:]]*temp-read[[:space:]]*=[[:space:]]*"?sysfs"?' "$conf"; then
        local hwmon_temp="/sys/bus/pci/devices/0000:01:00.0/hwmon/hwmon1/temp1_input"
        if [ ! -r "$hwmon_temp" ] || ! cat "$hwmon_temp" >/dev/null 2>&1; then
            bad_temp_read=1
            has_issue=1
        fi
    fi

    if [ "$has_issue" = 0 ]; then
        echo -e "  ${GREEN}✓${NC} Cyan Skillfish GPU Governor config is verified safe (kernel DPM mode)"
        return 0
    fi

    echo -e "  ${YELLOW}⚠ POTENTIAL SMU CONFLICT IN GOVERNOR CONFIG:${NC}"
    echo -e "    File: ${BOLD}$conf${NC}"
    if [ "$bad_set_method" = 1 ]; then
        echo -e "    ${YELLOW}• set-method = \"smu\"${NC} writes raw PCI config offset 0xb8 from userspace."
        echo -e "      On modern kernels, this collides with kernel SMU mailbox queries, causing timeouts and GPU ring resets."
        echo -e "      ${CYAN}-> Recommended: set-method = \"kernel\"${NC}"
    fi
    if [ "$bad_fix_metrics" = 1 ]; then
        echo -e "    ${YELLOW}• fix-metrics = true${NC} floods SMU Queue 3 with msg 0x3c polling."
        echo -e "      ${CYAN}-> Recommended: fix-metrics = false${NC}"
    fi
    if [ "$bad_temp_read" = 1 ]; then
        echo -e "    ${YELLOW}• temp-read = \"sysfs\"${NC} fails on this kernel with 'Operation not supported' (os error 95)."
        echo -e "      ${CYAN}-> Recommended: temp-read = \"drm\"${NC}"
    fi

    local do_patch=0
    if [ "$FIX_GOVERNOR_FLAG" = 1 ]; then
        do_patch=1
    elif [ -t 0 ] && [ "$DRY_RUN_FLAG" = 0 ]; then
        echo
        echo -ne "    ${BOLD}Would you like to automatically patch $conf to safe values? [Y/n]: ${NC}"
        read -r reply
        case "$reply" in
            [nN]*) do_patch=0 ;;
            *) do_patch=1 ;;
        esac
    fi

    if [ "$do_patch" = 1 ]; then
        patch_governor_config "$conf"
    else
        echo -e "    ${DIM}Governor config left untouched. Please update manually if you experience SMU timeouts.${NC}"
    fi
}

patch_governor_config() {
    local conf="${1:-/etc/cyan-skillfish-governor-smu/config.toml}"
    [ -f "$conf" ] || return 0

    local backup="${conf}.bak.$(date +%Y%m%d%H%M%S)"
    echo -e "    Creating backup at ${BOLD}$backup${NC}..."

    local use_sudo=""
    if [ ! -w "$conf" ] && command -v sudo >/dev/null 2>&1 && [ "$EUID" -ne 0 ]; then
        use_sudo="sudo"
    fi

    $use_sudo cp "$conf" "$backup"
    $use_sudo sed -i -E 's/^[[:space:]]*set-method[[:space:]]*=[[:space:]]*"?smu"?/set-method = "kernel"/' "$conf"
    $use_sudo sed -i -E 's/^[[:space:]]*fix-metrics[[:space:]]*=[[:space:]]*true/fix-metrics = false/' "$conf"
    $use_sudo sed -i -E 's/^[[:space:]]*fix-freq[[:space:]]*=[[:space:]]*true/fix-freq = false/' "$conf"
    if ! cat /sys/bus/pci/devices/0000:01:00.0/hwmon/hwmon1/temp1_input >/dev/null 2>&1; then
        $use_sudo sed -i -E 's/^[[:space:]]*temp-read[[:space:]]*=[[:space:]]*"?sysfs"?/temp-read = "drm"/' "$conf"
    fi
    if [ "$conf" = "/etc/cyan-skillfish-governor-smu/config.toml" ] && systemctl is-active --quiet cyan-skillfish-governor-smu.service 2>/dev/null; then
        echo -e "    Restarting cyan-skillfish-governor-smu.service..."
        $use_sudo systemctl restart cyan-skillfish-governor-smu.service || true
    fi
    echo -e "    ${GREEN}✓ Successfully updated $conf to safe kernel DPM mode!${NC}"
}

parse_install_args() {
    DASHBOARD_FLAG=""
    MEMORY_TEMP_FLAG=auto
    MEMORY_MODE_FLAG=detect
    COMPONENTS_FLAG=""
    DRY_RUN_FLAG=0
    FIX_GOVERNOR_FLAG=0

    for arg in "$@"; do
        case "$arg" in
            --memory-temp)
                MEMORY_TEMP_FLAG=1
                ;;
            --no-memory-temp)
                MEMORY_TEMP_FLAG=0
                ;;
            --memory-mode=*)
                MEMORY_MODE_FLAG="${arg#--memory-mode=}"
                ;;
            --dashboard=*)
                DASHBOARD_FLAG="${arg#--dashboard=}"
                ;;
            --components=*)
                COMPONENTS_FLAG="${arg#--components=}"
                ;;
            --fix-governor)
                FIX_GOVERNOR_FLAG=1
                ;;
            --dry-run)
                DRY_RUN_FLAG=1
                ;;
            *)
                echo "Warning: unrecognized option '$arg' — ignoring it." >&2
                ;;
        esac
    done
}

# Empty/invalid input retains the existing setting (off on a fresh install).
# Only an explicit "no" (or --no-memory-temp) is an opt-out: a missing answer,
# no terminal or a timeout must never remove a working memory collector.
memory_choice() {
    local answer="$1" fallback="$2"
    case "$answer" in
        y|Y|yes|YES|так|Так|1) echo 1 ;;
        n|N|no|NO|ні|Ні|0) echo 0 ;;
        "") echo "$fallback" ;;
        *) echo "Unrecognized answer; keeping the current memory setting." >&2
           echo "$fallback" ;;
    esac
}

# Sets MEMORY_ENABLED (install/keep the collector) and MEMORY_OPT_OUT (the user
# explicitly declined, so an installed collector may be removed).
choose_memory_monitoring() {
    local existing="$1" answer="" hint="y/N"
    MEMORY_ENABLED="$existing"
    MEMORY_OPT_OUT=0
    if [ "$MEMORY_TEMP_FLAG" != auto ]; then
        MEMORY_ENABLED="$MEMORY_TEMP_FLAG"
        if [ "$MEMORY_TEMP_FLAG" = 0 ]; then MEMORY_OPT_OUT=1; fi
    elif [ -t 0 ]; then
        [ "$existing" = 1 ] && hint="Y/n"
        read -r -t 30 -p $'\033[1m  ? Enable GDDR6 memory temperatures\033[0m (experimental; BC-250 P3.0 or BIOS with the patch) ['"$hint"']: ' answer || answer=""
        MEMORY_ENABLED="$(memory_choice "$answer" "$existing")"
        case "$answer" in n|N|no|NO|ні|Ні|0) MEMORY_OPT_OUT=1 ;; esac
    fi
}

# Decide how bc250-memory.service reaches the temperature payload. Sets
# MEMORY_MODE (reader-only|auto) and MEMORY_MODE_NOTE (human explanation).
#   --memory-mode=reader-only|auto  forced
#   detect (default)  a read-only probe of the live SMU: a payload installed by
#                     the BIOS means reader-only (no unlock, no SRAM writes);
#                     anything else keeps auto (the service installs it itself).
# The probe is skipped, keeping the existing mode, while the collector service
# is running (it owns the SMU). MEMORY_PROBE_CMD may be overridden (tests).
resolve_memory_mode() {
    MEMORY_MODE=auto
    MEMORY_MODE_NOTE=""
    case "$MEMORY_MODE_FLAG" in
        reader-only|auto)
            MEMORY_MODE="$MEMORY_MODE_FLAG"
            MEMORY_MODE_NOTE="forced by --memory-mode=$MEMORY_MODE_FLAG"
            return 0 ;;
        detect) ;;
        *) echo "Invalid --memory-mode '$MEMORY_MODE_FLAG' (use auto, reader-only or detect)" >&2
           return 1 ;;
    esac
    if systemctl is-active --quiet bc250-memory.service 2>/dev/null; then
        MEMORY_MODE="$(sed -n 's/^BC250_MEMORY_MODE=//p' "${MEMORY_CONF:-/etc/bc250-memory.conf}" 2>/dev/null | tail -n1)"
        case "$MEMORY_MODE" in reader-only|auto) ;; *) MEMORY_MODE=auto ;; esac
        MEMORY_MODE_NOTE="collector is running; keeping its current mode"
        return 0
    fi
    local label=""
    label="$(${MEMORY_PROBE_CMD:-sudo python3 -B "$SCRIPT_DIR/memory/collector.py" --probe} 2>/dev/null | tail -n1)" || true
    case "$label" in
        firmware-original|firmware-bounded|firmware-modern)
            MEMORY_MODE=reader-only
            MEMORY_MODE_NOTE="BIOS already installed the temperature payload (${label#firmware-}); no unlock needed" ;;
        none)
            MEMORY_MODE_NOTE="no payload in the BIOS; the service installs it itself (needs BIOS P3.00)" ;;
        linux)
            MEMORY_MODE_NOTE="this boot's SMU payload was installed from Linux; mode unchanged" ;;
        *)
            MEMORY_MODE_NOTE="BIOS payload not recognised (${label:-probe failed}); using the default install path" ;;
    esac
}

# An installed collector counts as "existing" when it is enabled or running
# right now; a unit the user deliberately left disabled is not re-enabled.
memory_service_existing() {
    systemctl is-enabled --quiet bc250-memory.service 2>/dev/null ||
        systemctl is-active --quiet bc250-memory.service 2>/dev/null
}

# Echoes "nct6683" or "nct6687" if either sensor module is already loaded,
# empty otherwise. install.sh only sets up nct6683 when this comes back empty
# — an already-active driver (from a previous run, or the distro itself) is
# left as is.
detect_active_sensor_driver() {
    # Capture first: "cmd | grep -q" fails under pipefail when grep exits early
    # and cmd dies of SIGPIPE.
    local loaded
    loaded="$(lsmod 2>/dev/null || true)"
    if grep -q '^nct6687 ' <<<"$loaded"; then
        echo "nct6687"
    elif grep -q '^nct6683 ' <<<"$loaded"; then
        echo "nct6683"
    else
        echo ""
    fi
}

# State of a BC-250 kernel sensor module (bc250_vrm / bc250_memory, from
# linux-cachyos-bc250 or the Hexxeh *-dkms packages):
#   loaded      - loaded right now
#   autoload    - not loaded yet, but will be at boot: listed in modules-load.d,
#                 or its modalias matches this machine's DMI data (and it is
#                 not blacklisted)
#   blacklisted - installed but disabled
#   available   - installed, but nothing loads it: no modules-load.d entry and
#                 no matching alias (newer linux-cachyos-bc250 builds ship
#                 bc250_memory this way; it is opt-in)
#   ""          - not installed for the running kernel
# MODALIAS_FILE may be overridden (tests).
kernel_module_state() {
    local mod="$1"
    if [ -d "/sys/module/$mod" ]; then
        echo loaded
        return
    fi
    if grep -qsx "$mod" /etc/modules-load.d/*.conf /usr/lib/modules-load.d/*.conf /run/modules-load.d/*.conf; then
        echo autoload
        return
    fi
    if ! modinfo "$mod" >/dev/null 2>&1; then
        echo ""
        return
    fi
    # Capture command output first: under pipefail, "cmd | grep -q" reports
    # failure when grep exits early and cmd dies of SIGPIPE (the real
    # "modprobe --showconfig" prints ~2000 lines).
    local config resolved modalias
    config="$(modprobe --showconfig 2>/dev/null || true)"
    if grep -qx "blacklist $mod" <<<"$config"; then
        echo blacklisted
        return
    fi
    modalias="$(cat "${MODALIAS_FILE:-/sys/devices/virtual/dmi/id/modalias}" 2>/dev/null || true)"
    resolved=""
    if [ -n "$modalias" ]; then resolved="$(modprobe -R "$modalias" 2>/dev/null || true)"; fi
    if grep -qx "$mod" <<<"$resolved"; then
        echo autoload
    else
        echo available
    fi
}

# Prints the modprobe.d files that blacklist the given module (one per line).
# Matches only an exact "blacklist <module>" directive, ignoring comments.
# MODPROBE_DIRS may be overridden (tests).
blacklist_files_for() {
    local mod="$1" dir f
    for dir in ${MODPROBE_DIRS:-/etc/modprobe.d /usr/lib/modprobe.d /run/modprobe.d /lib/modprobe.d}; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*.conf; do
            [ -f "$f" ] || continue
            if grep -Eq "^[[:space:]]*blacklist[[:space:]]+$mod[[:space:]]*(#.*)?$" "$f"; then
                echo "$f"
            fi
        done
    done
}

# True when the kernel bc250_memory driver owns (or will own after a reboot)
# GDDR6 reads. bc250-memory.service must not run alongside it: both send SMU
# queue 3 messages and collide (SMU wedges, fans ramp up).
kernel_memory_driver_active() {
    case "$(kernel_module_state bc250_memory)" in
        loaded|autoload) return 0 ;;
        *) return 1 ;;
    esac
}

write_sensor_driver_configs() {
    sudo mkdir -p /etc/modules-load.d /etc/modprobe.d
    echo "nct6683" | sudo tee /etc/modules-load.d/99-sensors.conf > /dev/null
    echo "options nct6683 force=true" | sudo tee /etc/modprobe.d/sensors.conf > /dev/null
}

load_sensor_driver() {
    sudo modprobe nct6683 force=true
}

# Rejects a "successful" build/prebuilt binary that isn't actually a valid
# ELF executable — a corrupted download, wrong architecture, or empty
# placeholder would otherwise sail through STEP 2 and only surface much
# later, when systemd tries (and fails) to start the service.
verify_binary() {
    local bin="$1"
    if [ ! -s "$bin" ]; then
        return 1
    fi
    local magic
    magic="$(head -c4 "$bin" 2>/dev/null | od -An -tx1 | tr -d ' \n')"
    [ "$magic" = "7f454c46" ]
}

supports_memory_snapshot() {
    verify_binary "$1" &&
        LC_ALL=C grep -aFq 'BC250_TELEMETRY_FEATURES=memory_snapshot_v1' "$1"
}

# Feature tokens are listed in the BC250_TELEMETRY_FEATURES marker string
# compiled into the daemon; inspecting it never executes the binary.
binary_has_feature() {
    verify_binary "$1" || return 1
    local features
    features="$(LC_ALL=C grep -aoE 'BC250_TELEMETRY_FEATURES=[a-z0-9_,]+' "$1" || true)"
    features="${features%%$'\n'*}"
    case ",${features#*=}," in
        *",$2,"*) return 0 ;;
        *) return 1 ;;
    esac
}

# Resolve an explicit component list into flags. Default preserves the original
# full install behavior; omitted optional components are preserved, never removed.
resolve_install_components() {
    COMPONENT_DAEMON=0 COMPONENT_WEB=0 COMPONENT_MEMORY=0 COMPONENT_NUVOTON=0 COMPONENT_PLASMA=0
    local list="${COMPONENTS_FLAG:-daemon,web,memory,nuvoton,plasma}" item
    [ -n "$COMPONENTS_FLAG" ] || list="daemon,web,memory,nuvoton,plasma"
    local IFS=,
    for item in $list; do
        case "$item" in
            daemon) COMPONENT_DAEMON=1 ;;
            web) COMPONENT_WEB=1 ;;
            memory) COMPONENT_MEMORY=1 ;;
            nuvoton) COMPONENT_NUVOTON=1 ;;
            plasma) COMPONENT_PLASMA=1 ;;
            "") echo "Empty component name" >&2; return 1 ;;
            *) echo "Unknown install component: $item" >&2; return 1 ;;
        esac
    done
    [ "$COMPONENT_DAEMON" = 1 ] || { echo "daemon component is required" >&2; return 1; }
}

print_install_plan() {
    local selected=""
    [ "$COMPONENT_DAEMON" = 1 ] && selected="daemon"
    [ "$COMPONENT_WEB" = 1 ] && selected="${selected:+$selected,}web"
    [ "$COMPONENT_MEMORY" = 1 ] && selected="${selected:+$selected,}memory"
    [ "$COMPONENT_NUVOTON" = 1 ] && selected="${selected:+$selected,}nuvoton"
    [ "$COMPONENT_PLASMA" = 1 ] && selected="${selected:+$selected,}plasma"
    printf 'Install components: %s\n' "$selected"
    [ "$COMPONENT_MEMORY" = 1 ] && printf 'Memory mode: %s\n' "$MEMORY_MODE_FLAG"
    [ "$COMPONENT_WEB" = 1 ] || printf 'Preserve existing web service and dashboard config\n'
    [ "$COMPONENT_MEMORY" = 1 ] || printf 'Preserve existing memory service and data\n'
    [ "$COMPONENT_NUVOTON" = 1 ] || printf 'Preserve existing Nuvoton configuration\n'
}
