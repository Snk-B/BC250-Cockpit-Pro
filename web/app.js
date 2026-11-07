const state = {};
const SMOOTHING = 0.08;
const SMOOTHING_CRISP = 0.2; // for temps/fans — smooth, but without noticeable lag
let latest = null; // last known-valid frame — same as v1: never show a fake 0
let frameReady = false; // true exactly once per new telemetry frame (~700ms) — gates the chart history push
let latestReceivedAt = null;
let telemetryFetchFailed = false;

// The daemon publishes a frame roughly every 700 ms, so a window in seconds
// converts to a point count. The buffer always holds the longest window on
// offer; a shorter selection draws its tail, so switching down and back up
// loses nothing.
const POLL_MS = 700;
const WINDOWS = [
    { secs: 30,  label: '30S' },
    { secs: 60,  label: '1M'  },
    { secs: 120, label: '2M'  },
];
const DEFAULT_WINDOW = 30;
const pointsFor = (secs) => Math.round((secs * 1000) / POLL_MS);
const HISTORY_MAX = pointsFor(WINDOWS[WINDOWS.length - 1].secs);
const history = { cpuTemp: [], cpuFreq: [], gpuTemp: [], gpuClock: [] };

let windowSecs = DEFAULT_WINDOW;
let cpuWindowSecs = DEFAULT_WINDOW;
let gpuWindowSecs = DEFAULT_WINDOW;
try {
    const savedCpu = parseInt(localStorage.getItem('bc250.cpuChartWindow'), 10);
    if (WINDOWS.some((w) => w.secs === savedCpu)) cpuWindowSecs = savedCpu;
    const savedGpu = parseInt(localStorage.getItem('bc250.gpuChartWindow'), 10);
    if (WINDOWS.some((w) => w.secs === savedGpu)) gpuWindowSecs = savedGpu;
} catch (e) { /* private window or blocked storage: keep the default */ }

function pushHistory(key, value) {
    const arr = history[key];
    arr.push(value);
    if (arr.length > HISTORY_MAX) arr.shift();
}

// The tail of a series for the selected window. Having fewer points than the
// window asks for is normal right after load — spark() draws what it is given.
const inWindow = (key, secs = windowSecs) => history[key].slice(-pointsFor(secs));


function updatePulseDot(id, values, w, h, minRange = 0) {
    // Pulse dot decommissioned per user request — clean stroke with subtle glow retained
}

function drawCharts() {
    // minRange: keeps a few tenths of a degree / a couple hundred MHz of noise
    // from filling the whole chart height — the real range has to be sizeable
    // enough to actually earn that space.
    setPath('v2-cpu-chart-area', spark(inWindow('cpuTemp', cpuWindowSecs), 200, 100, true, 6));
    setPath('v2-cpu-chart-temp', spark(inWindow('cpuTemp', cpuWindowSecs), 200, 100, false, 6));
    setPath('v2-cpu-chart-freq', spark(inWindow('cpuFreq', cpuWindowSecs), 200, 100, false, 200));
    setPath('v2-gpu-chart-area', spark(inWindow('gpuTemp', gpuWindowSecs), 200, 100, true, 6));
    setPath('v2-gpu-chart-temp', spark(inWindow('gpuTemp', gpuWindowSecs), 200, 100, false, 6));
    setPath('v2-gpu-chart-freq', spark(inWindow('gpuClock', gpuWindowSecs), 200, 100, false, 200));

    // Clean stroke waveform with subtle glow (no trailing dots)
}

function setCpuWindow(secs) {
    cpuWindowSecs = secs;
    try { localStorage.setItem('bc250.cpuChartWindow', String(secs)); } catch (e) { /* ignore */ }
    const group = document.getElementById('v2-cpu-win-group') || document.querySelector('#v2-cpu-chart')?.closest('.c2-chart-card');
    group?.querySelectorAll('.win-btn').forEach((btn) => {
        const on = Number(btn.dataset.secs) === secs;
        btn.classList.toggle('is-on', on);
        btn.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    drawCharts();
}

function setGpuWindow(secs) {
    gpuWindowSecs = secs;
    try { localStorage.setItem('bc250.gpuChartWindow', String(secs)); } catch (e) { /* ignore */ }
    const group = document.getElementById('v2-gpu-win-group') || document.querySelector('#v2-gpu-chart')?.closest('.c2-chart-card');
    group?.querySelectorAll('.win-btn').forEach((btn) => {
        const on = Number(btn.dataset.secs) === secs;
        btn.classList.toggle('is-on', on);
        btn.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    drawCharts();
}

function setWindow(secs) {
    setCpuWindow(secs);
    setGpuWindow(secs);
}

document.addEventListener('DOMContentLoaded', () => {
    const cpuGroup = document.getElementById('v2-cpu-win-group');
    if (cpuGroup) {
        cpuGroup.querySelectorAll('.win-btn').forEach((btn) => {
            btn.addEventListener('click', () => setCpuWindow(Number(btn.dataset.secs)));
        });
    }
    const gpuGroup = document.getElementById('v2-gpu-win-group');
    if (gpuGroup) {
        gpuGroup.querySelectorAll('.win-btn').forEach((btn) => {
            btn.addEventListener('click', () => setGpuWindow(Number(btn.dataset.secs)));
        });
    }
    setCpuWindow(cpuWindowSecs);
    setGpuWindow(gpuWindowSecs);

        // Basic / Advanced Dashboard Mode Controller & Persistence with Smooth Morphing Transition
    let isTransitioningMode = false;
    function applyDashboardModeClasses(mode) {
        const isBasic = (mode === 'basic');
        document.body.classList.toggle('mode-basic', isBasic);
        document.body.classList.toggle('mode-advanced', !isBasic);

        const btnBasic = document.getElementById('btn-mode-basic');
        const btnAdv = document.getElementById('btn-mode-advanced');
        if (btnBasic && btnAdv) {
            btnBasic.classList.toggle('active', isBasic);
            btnBasic.setAttribute('aria-selected', isBasic ? 'true' : 'false');
            btnAdv.classList.toggle('active', !isBasic);
            btnAdv.setAttribute('aria-selected', !isBasic ? 'true' : 'false');
        }

        const badge = document.getElementById('hud-mode-badge');
        if (badge) {
            badge.textContent = isBasic ? 'TITANIUM BASIC HUD' : 'TITANIUM ADVANCED STUDIO';
        }

        try {
            localStorage.setItem('bc250_dash_mode', isBasic ? 'basic' : 'advanced');
        } catch (_) {}
    }

    function setDashboardMode(mode, immediate = false) {
        const currentMode = document.body.classList.contains('mode-advanced') ? 'advanced' : 'basic';
        if (immediate || currentMode === mode) {
            applyDashboardModeClasses(mode);
            return;
        }

        if (isTransitioningMode) return;
        isTransitioningMode = true;

        document.body.classList.add('mode-transitioning');
        setTimeout(() => {
            applyDashboardModeClasses(mode);
            setTimeout(() => {
                document.body.classList.remove('mode-transitioning');
                isTransitioningMode = false;
            }, 260);
        }, 110);
    }

    let savedDashMode = 'basic';
    try {
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.has('mode')) {
            savedDashMode = urlParams.get('mode') === 'advanced' ? 'advanced' : 'basic';
        } else {
            savedDashMode = localStorage.getItem('bc250_dash_mode') || 'basic';
        }
    } catch (_) {}
    setDashboardMode(savedDashMode, true);

    document.getElementById('btn-mode-basic')?.addEventListener('click', () => setDashboardMode('basic'));
    document.getElementById('btn-mode-advanced')?.addEventListener('click', () => setDashboardMode('advanced'));

    // Micro-Fit 12V Auxiliary Power Toggle & Persistence
    const microfitToggle = document.getElementById('v2-microfit-toggle');
    const microfitFlow = document.getElementById('bc-microfit-flow-group');
    function setMicrofitState(enabled) {
        if (!microfitToggle) return;
        microfitToggle.classList.toggle('active', enabled);
        microfitToggle.classList.toggle('is-active', enabled);
        microfitToggle.setAttribute('aria-pressed', enabled ? 'true' : 'false');
        if (microfitFlow) microfitFlow.style.display = enabled ? 'inline' : 'none';
        try {
            localStorage.setItem('bc250_microfit_power', enabled ? '1' : '0');
        } catch (_) {}
    }
    let savedMicrofit = false; // Default: FALSE (bus-only power by default)
    try {
        const stored = localStorage.getItem('bc250_microfit_power');
        if (stored !== null) savedMicrofit = (stored === '1');
    } catch (_) {}
    setMicrofitState(savedMicrofit);
    if (microfitToggle) {
        // Suppress mobile virtual focus box and clear active touch focus
        const clearFocus = () => { try { microfitToggle.blur(); } catch (_) {} };
        microfitToggle.addEventListener('pointerdown', clearFocus);
        microfitToggle.addEventListener('pointerup', clearFocus);
        microfitToggle.addEventListener('touchstart', clearFocus, { passive: true });
        microfitToggle.addEventListener('touchend', clearFocus, { passive: true });
        microfitToggle.addEventListener('focus', () => {
            if (window.matchMedia('(pointer: coarse)').matches) {
                clearFocus();
            }
        });

        microfitToggle.addEventListener('click', () => {
            clearFocus();
            const active = microfitToggle.classList.contains('active') || microfitToggle.classList.contains('is-active');
            setMicrofitState(!active);
        });

    // One-Time Micro-Fit 12V Auxiliary Power Callout Pop-up
    function initMicrofitPopover() {
        const popover = document.getElementById('mfit-popover');
        if (!popover) return;

        let hintSeen = false;
        try {
            hintSeen = (localStorage.getItem('bc250_microfit_hint_seen') === '1');
        } catch (_) {}

        if (hintSeen) return;

        const titleEl = document.getElementById('mfit-popover-title-text');
        const textEl = document.getElementById('mfit-popover-text');
        const dismissEl = document.getElementById('mfit-popover-dismiss');

        if (titleEl) titleEl.textContent = '12V AUXILIARY POWER';
        if (textEl) {
            textEl.textContent = 'Powering via 12V Micro-Fit cable? Click here to toggle auxiliary telemetry and animated current flow on the board.';
        }
        if (dismissEl) dismissEl.textContent = 'Got it';

        const dismissPopover = () => {
            if (popover.classList.contains('dismissing')) return;
            popover.classList.add('dismissing');
            try {
                localStorage.setItem('bc250_microfit_hint_seen', '1');
            } catch (_) {}
            setTimeout(() => {
                popover.classList.add('hidden');
                popover.classList.remove('dismissing');
            }, 250);
        };

        document.getElementById('mfit-popover-close')?.addEventListener('click', (e) => {
            e.stopPropagation();
            dismissPopover();
        });

        dismissEl?.addEventListener('click', (e) => {
            e.stopPropagation();
            dismissPopover();
        });

        // Also dismiss automatically if the user clicks the toggle itself
        microfitToggle?.addEventListener('click', () => {
            dismissPopover();
        });

        // Show after 1200ms delay on first visit
        setTimeout(() => {
            if (!popover.classList.contains('dismissing')) {
                popover.classList.remove('hidden');
                popover.setAttribute('aria-hidden', 'false');
            }
        }, 1200);
    }
    initMicrofitPopover();

        microfitToggle.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                const active = microfitToggle.classList.contains('active') || microfitToggle.classList.contains('is-active');
                setMicrofitState(!active);
            }
        });
    }
});

// Catmull-Rom -> cubic Bezier: a single pass over the points gives a smooth
// curve with no canvas/rAF involved.
// minRange is a floor on the Y auto-scale range: without it, tiny sensor
// noise (say ±0.3°C) would get stretched across the full chart height and
// read as sharp spikes.
// Tangents are further damped by TENSION, and control points are hard-clamped
// to [0,h] — thanks to the Bezier convex-hull property, the curve then simply
// cannot escape the container bounds, even on sharp zigzags.
const SPARK_TENSION = 0.6;
function spark(values, w, h, close, minRange = 0) {
    if (values.length < 2) return '';
    let min = Math.min(...values), max = Math.max(...values);
    if (max - min < minRange) {
        const mid = (max + min) / 2;
        min = mid - minRange / 2;
        max = mid + minRange / 2;
    }
    if (max - min < 1e-6) { min -= 1; max += 1; }
    const stepX = w / (values.length - 1);
    const clampY = (y) => Math.max(0, Math.min(h, y));
    const p = values.map((v, i) => [
        i * stepX,
        h - ((v - min) / (max - min)) * (h - 14) - 7 // margin absorbs Bezier overshoot
    ]);
    const n = (i) => p[Math.max(0, Math.min(p.length - 1, i))];
    const f = (v) => v.toFixed(2);
    let d = `M ${f(p[0][0])} ${f(clampY(p[0][1]))}`;
    for (let i = 0; i < p.length - 1; i++) {
        const p0 = n(i - 1), p1 = p[i], p2 = p[i + 1], p3 = n(i + 2);
        d += ` C ${f(p1[0] + (p2[0] - p0[0]) / 6 * SPARK_TENSION)} ${f(clampY(p1[1] + (p2[1] - p0[1]) / 6 * SPARK_TENSION))}`
          +  ` ${f(p2[0] - (p3[0] - p1[0]) / 6 * SPARK_TENSION)} ${f(clampY(p2[1] - (p3[1] - p1[1]) / 6 * SPARK_TENSION))}`
          +  ` ${f(p2[0])} ${f(clampY(p2[1]))}`;
    }
    return close ? d + ` L ${w} ${h} L 0 ${h} Z` : d;
}

const TEMP_THRESH = {
    die: [70, 85, 95],    // CPU/GPU die
    vrm: [60, 75, 90],    // VRM mosfets
    nvme: [55, 65, 75],   // NVMe
    board: [45, 55, 65],  // Board/ambient (nct_t14/t15 thermistors)
};

function statusFor(value, [warnAt, seriousAt, criticalAt]) {
    if (value >= criticalAt) return 'status-critical';
    if (value >= seriousAt) return 'status-serious';
    if (value >= warnAt) return 'status-warning';
    return 'status-good';
}

function setText(id, text) {
    const el = document.getElementById(id);
    if (el && el.textContent !== text) el.textContent = text;
}

function setStatusClass(id, value, thresholds) {
    const el = document.getElementById(id);
    if (!el) return;
    const status = statusFor(value, thresholds);
    if (el.dataset.status === status) return;
    el.classList.remove('status-good', 'status-warning', 'status-serious', 'status-critical');
    el.classList.add(status);
    el.dataset.status = status;
}

// stockAt/maxAt are real reference points for this SKU (6 cores / 24 CU is
// the commonly cited factory baseline per bc250-toolkit and
// bc250-cu-live-manager; 8 cores / 40 CU is the architectural ceiling — same
// silicon in every BC-250). A permanent partial unlock above stock (say
// 38/40) isn't broken or incomplete, it's just this die's real ceiling — so
// it gets its own steady color rather than being lumped in with either end.
function setCoreBadgeClass(id, count, stockAt, maxAt) {
    const el = document.getElementById(id);
    if (!el) return;
    const cls = count >= maxAt ? 'cores-maxed' : count > stockAt ? 'cores-partial' : 'cores-stock';
    if (el.dataset.coreClass === cls) return;
    el.classList.remove('cores-maxed', 'cores-partial', 'cores-stock');
    el.classList.add(cls);
    el.dataset.coreClass = cls;
}

// Chip-reported STATUS_TEMPERATURE/STATUS_IOUT fault/warning bits — only
// shown when the PMIC itself has latched the bit, never a software-guessed threshold.
function setFaultBadge(id, warning, fault, kind) {
    const el = document.getElementById(id);
    if (!el) return;
    const badgeState = fault ? 'fault' : (warning ? 'warning' : 'none');
    if (el.dataset.faultState === badgeState) return;
    el.classList.remove('active-warning', 'active-fault');
    if (badgeState === 'fault') {
        el.classList.add('active-fault');
        el.textContent = 'FAULT';
        el.title = `PMIC ${kind} FAULT bit is set`;
    } else if (badgeState === 'warning') {
        el.classList.add('active-warning');
        el.textContent = 'WARN';
        el.title = `PMIC ${kind} WARNING bit is set`;
    } else {
        el.textContent = '';
        el.title = '';
    }
    el.dataset.faultState = badgeState;
}

function setDisplay(id, show) {
    const el = document.getElementById(id);
    if (!el) return;
    const wanted = show ? '' : 'none';
    if (el.style.display !== wanted) el.style.display = wanted;
}

function setPath(id, d) {
    const el = document.getElementById(id);
    if (el && el.getAttribute('d') !== d) el.setAttribute('d', d);
}

function setBar(id, value, max) {
    const el = document.getElementById(id);
    if (!el) return;
    const m = max !== undefined ? max : parseFloat(el.dataset.max);
    let percent = value / m;
    if (percent > 1) percent = 1;
    if (percent < 0) percent = 0;
    const width = (percent * 100).toFixed(1) + '%';
    if (el.style.width !== width) el.style.width = width;
}

function smooth(key, targetValue, factor = SMOOTHING) {
    if (state[key] === undefined) {
        state[key] = targetValue;
    } else {
        const diff = targetValue - state[key];
        state[key] = Math.abs(diff) < 0.05 ? targetValue : state[key] + diff * factor;
    }
    return state[key];
}

// Touch only animation-duration, and only on a meaningful change — rewriting the
// whole `animation` shorthand restarts the keyframes and reads as a visible stutter.
const durations = {};
function setDuration(id, seconds) {
    const el = document.getElementById(id);
    if (!el) return;
    if (!seconds) {
        if (durations[id] !== 0) {
            el.style.animationPlayState = 'paused';
            durations[id] = 0;
        }
        return;
    }
    const prev = durations[id];
    if (prev === 0) el.style.animationPlayState = 'running';
    if (prev && Math.abs(seconds - prev) / prev < 0.08) return;
    el.style.animationDuration = seconds.toFixed(2) + 's';
    durations[id] = seconds;
}

function setGlow(id, watts, max) {
    const el = document.getElementById(id);
    if (!el) return;
    el.setAttribute('opacity', (0.15 + Math.min(1, watts / max) * 0.75).toFixed(3));
}

// Renders the SVG board's live state: heat glow (driven by SMU PPT), VRM
// glow intensity, fan speed, and the "current flow" animation on the traces.
function paintBoard(ppt, cpuPout, gpuPout, fanRpm, totalPower) {
    // Same 150/180W thresholds as the .ppt-item warning/critical classes on the SMU PPT card.
    const heat = Math.min(1, Math.max(0, ppt / 200));
    const heatEl = document.getElementById('bc-heat');
    if (heatEl) {
        heatEl.setAttribute('opacity', (0.18 + heat * 0.78).toFixed(3));
        heatEl.setAttribute('rx', String(96 + heat * 58));
        heatEl.setAttribute('ry', String(76 + heat * 44));
        const gradId = ppt >= 180 ? 'bc-heat-grad-crit' : ppt >= 150 ? 'bc-heat-grad-warn' : 'bc-heat-grad';
        const wantFill = `url(#${gradId})`;
        if (heatEl.getAttribute('fill') !== wantFill) heatEl.setAttribute('fill', wantFill);
    }

    setDuration('bc-fan1-blades', fanRpm > 40 ? Math.max(0.3, 2200 / fanRpm) : 0);

    // Anti-aliasing speed formula:
    // Period is 40px (12px dash + 28px gap). Total cycle distance is 240px.
    // To prevent the stroboscopic wagon-wheel effect (moving backwards at 60Hz/120Hz/144Hz),
    // the frame displacement must stay strictly under half-period (< 20px).
    // Clamping min duration to 0.80s keeps displacement <= 5.0px per frame,
    // ensuring crisp, smooth, 100% unidirectional FORWARD electric rush even at 220W+!
    const speed = Math.max(0.80, 3.6 - Math.min(2.8, (totalPower - 15) * 0.0155));
    ['bc-power-flow', 'bc-power-flow-microfit', 'bc-power-flow-microfit2', 'bc-vrm-flow-cpu', 'bc-vrm-flow-gpu'].forEach(id => setDuration(id, speed));

    setGlow('bc-cpu-vrm-glow', cpuPout, 30);
    setGlow('bc-gpu-vrm-glow', gpuPout, 130);
}

function updateUI() {
    // If memory.js failed to load, BC250Memory is undeclared; the typeof guard
    // skips the memory panel rather than throwing here and killing the entire
    // dashboard. (A top-level `const` is not a property of window, so a
    // `window.BC250Memory?.` guard would wrongly skip it even when loaded.)
    if (typeof BC250Memory !== 'undefined') {
        BC250Memory.render(latest?.memory,
            latestReceivedAt == null ? null : performance.now() - latestReceivedAt, telemetryFetchFailed);
    }
    if (!latest) return;
    const hw = latest.hardware || {};
    const sw = latest.software || {};
    const cl = latest.cooling || {};
    const cpu = hw.cpu || {};
    const gpu = hw.gpu || {};

    const pick = (v, fallback) => (typeof v === 'number' && v >= 0 ? v : fallback);
    const p = state.prevFrame || {};

    const cpuDie = pick(sw.cpu_temp_c, p.cpuDie ?? 0);
    const gpuDie = pick(sw.gpu_temp_c, p.gpuDie ?? 0);
    const cpuFreq = pick(sw.cpu_freq_mhz, p.cpuFreq ?? 0);
    const gpuClock = pick(sw.gpu_sclk_mhz, p.gpuClock ?? 0);
    const ppt = pick(sw.gpu_ppt_w, p.ppt ?? 0);
    const nvme = pick(sw.nvme_temp_c, p.nvme ?? 0);
    const t14 = pick(sw.nct_t14_c, p.t14 ?? 0);
    const t15 = pick(sw.nct_t15_c, p.t15 ?? 0);
    const fanRpm = pick(cl.fan_rpm, p.fanRpm ?? 0);
    const fanPwm = pick(cl.fan_pwm_pct, p.fanPwm ?? 0);

    const cpuVin = cpu.valid ? cpu.vin : (p.cpuVin ?? 0);
    const cpuVout = cpu.valid ? cpu.vout : (p.cpuVout ?? 0);
    const cpuIout = cpu.valid ? cpu.iout : (p.cpuIout ?? 0);
    const cpuPout = cpu.valid ? cpu.pout : (p.cpuPout ?? 0);
    const cpuT = cpu.valid ? cpu.temp : (p.cpuT ?? 0);
    const cpuTempWarning = cpu.valid ? !!cpu.temp_warning : (p.cpuTempWarning ?? false);
    const cpuTempFault = cpu.valid ? !!cpu.temp_fault : (p.cpuTempFault ?? false);
    const cpuIoutWarning = cpu.valid ? !!cpu.iout_warning : (p.cpuIoutWarning ?? false);
    const cpuIoutFault = cpu.valid ? !!cpu.iout_fault : (p.cpuIoutFault ?? false);
    const gpuVin = gpu.valid ? gpu.vin : (p.gpuVin ?? 0);
    const gpuVout = gpu.valid ? gpu.vout : (p.gpuVout ?? 0);
    const gpuIout = gpu.valid ? gpu.iout : (p.gpuIout ?? 0);
    const gpuPout = gpu.valid ? gpu.pout : (p.gpuPout ?? 0);
    const gpuT = gpu.valid ? gpu.temp : (p.gpuT ?? 0);
    const gpuTempWarning = gpu.valid ? !!gpu.temp_warning : (p.gpuTempWarning ?? false);
    const gpuTempFault = gpu.valid ? !!gpu.temp_fault : (p.gpuTempFault ?? false);
    const gpuIoutWarning = gpu.valid ? !!gpu.iout_warning : (p.gpuIoutWarning ?? false);
    const gpuIoutFault = gpu.valid ? !!gpu.iout_fault : (p.gpuIoutFault ?? false);

    const total = pick(hw.total_power, cpuPout + gpuPout);

    state.prevFrame = {
        cpuDie, gpuDie, cpuFreq, gpuClock, ppt, nvme, t14, t15, fanRpm, fanPwm,
        cpuVin, cpuVout, cpuIout, cpuPout, cpuT, gpuVin, gpuVout, gpuIout, gpuPout, gpuT,
        cpuTempWarning, cpuTempFault, gpuTempWarning, gpuTempFault,
        cpuIoutWarning, cpuIoutFault, gpuIoutWarning, gpuIoutFault,
    };

    // --- History for the mini-charts (once per real telemetry frame, not per rAF tick) ---
    if (frameReady) {
        frameReady = false;
        pushHistory('cpuTemp', cpuDie);
        pushHistory('cpuFreq', cpuFreq);
        pushHistory('gpuTemp', gpuDie);
        pushHistory('gpuClock', gpuClock);
        drawCharts();
    }

    // pptVal is computed once here (not inside paintBoard) — calling smooth() twice
    // per frame with the same target value would double the smoothing step.
    const pptVal = smooth('ppt', ppt);

    // --- SVG board ---
    paintBoard(pptVal, smooth('cpuPout', cpuPout), smooth('gpuPout', gpuPout), smooth('fanRpm', fanRpm, SMOOTHING_CRISP), total);

    // --- BOARD · COOLING ---
    setText('v2-ppt', pptVal.toFixed(1));
    const pptStat = document.getElementById('v2-ppt-stat');
    if (pptStat) {
        pptStat.classList.toggle('ppt-critical', pptVal >= 180);
        pptStat.classList.toggle('ppt-warning', pptVal >= 150 && pptVal < 180);
    }
    setText('v2-fan-rpm', Math.round(smooth('fanRpmTxt', fanRpm, SMOOTHING_CRISP)).toString());
    setText('v2-fan-pwm', Math.round(smooth('fanPwm', fanPwm, SMOOTHING_CRISP)).toString());

    // Second (backplate) fan — the block and its SVG model only appear if the
    // daemon actually reports cooling.vrm_fan_rpm (field isn't guaranteed, degrade quietly).
    const hasBackFan = typeof cl.vrm_fan_rpm === 'number' && cl.vrm_fan_rpm >= 0;
    setDisplay('v2-fan2-hero', hasBackFan);
    const heroEl = document.getElementById('v2-board-hero');
    if (heroEl) heroEl.classList.toggle('has-backfan', hasBackFan);
    const backFanSvg = document.getElementById('bc-backplate-fan');
    if (backFanSvg) backFanSvg.style.display = hasBackFan ? '' : 'none';
    if (hasBackFan) {
        const fan2Rpm = smooth('fan2Rpm', cl.vrm_fan_rpm, SMOOTHING_CRISP);
        const fan2Pwm = typeof cl.vrm_fan_pwm_pct === 'number' ? cl.vrm_fan_pwm_pct : 0;
        setText('v2-fan2-rpm', Math.round(fan2Rpm).toString());
        setText('v2-fan2-pwm', Math.round(smooth('fan2Pwm', fan2Pwm, SMOOTHING_CRISP)).toString());
        setDuration('bc-fan2-blades', fan2Rpm > 40 ? Math.max(0.3, 2200 / fan2Rpm) : 0);
    } else {
        setDuration('bc-fan2-blades', 0);
    }

    // Memory/Fabric — same idea, gated on df_pstate/mem_clock_mhz being present in software.
    const hasMemInfo = typeof sw.df_pstate === 'number' && sw.df_pstate >= 0
        && typeof sw.mem_clock_mhz === 'number' && sw.mem_clock_mhz >= 0;
    setDisplay('v2-memory-clock-row', hasMemInfo);
    if (hasMemInfo) {
        const pstate = Math.round(sw.df_pstate);
        setText('v2-mem-state', 'P' + pstate);
        setText('v2-mem-clock', Math.round(smooth('memClock', sw.mem_clock_mhz)).toString());
        setBar('v2-mem-bar', Math.max(0, 100 - pstate * 25));
    }

    const board = (t14 + t15) / 2;
    const boardVal = smooth('board', board, SMOOTHING_CRISP);
    setText('v2-board-temp', boardVal.toFixed(1));
    setStatusClass('v2-board-temp-figure', boardVal, TEMP_THRESH.board);

    const nvmeVal = smooth('nvme', nvme, SMOOTHING_CRISP);
    setText('v2-nvme-temp', nvmeVal.toFixed(1));
    setBar('v2-nvme-temp-bar', nvmeVal);
    setStatusClass('v2-nvme-temp-figure', nvmeVal, TEMP_THRESH.nvme);
    setStatusClass('v2-nvme-temp-bar', nvmeVal, TEMP_THRESH.nvme);

    const t15Val = smooth('t15', t15, SMOOTHING_CRISP);
    setText('v2-vrmmos-temp', t15Val.toFixed(1));
    setStatusClass('v2-vrmmos-temp-figure', t15Val, TEMP_THRESH.vrm);

    const boardBarVal = (boardVal + t15Val) / 2;
    setBar('v2-board-temp-bar', boardBarVal);
    setStatusClass('v2-board-temp-bar', boardBarVal, TEMP_THRESH.board);

    setText('v2-rail-vin', cpuVin.toFixed(2));
    setBar('v2-rail-vin-bar', cpuVin);

    // --- CPU CORE ---
    // Core/CU badges are populated separately by fetchTopology() (see
    // bottom of file) — that data comes from a once-per-page-load request,
    // not this per-frame telemetry update.

    setText('v2-cpu-die', cpuDie.toFixed(1));
    setStatusClass('v2-cpu-die-unit', cpuDie, TEMP_THRESH.die);
    const cpuLoad = typeof sw.cpu_usage_pct === 'number' ? sw.cpu_usage_pct : 64;
    setText('v2-cpu-load', Math.round(smooth('cpuLoad', cpuLoad, SMOOTHING_CRISP)).toString());
    const smoothCpuClk = smooth('cpuFreq', cpuFreq);
    setText('v2-cpu-freq', Math.round(smoothCpuClk).toString());
    const cpuGauge = document.getElementById('c2-cpu-gauge');
    if (cpuGauge) {
        const cpuOffset = Math.max(0, 257.6 - (smoothCpuClk / 4000) * 257.6);
        cpuGauge.style.strokeDashoffset = cpuOffset.toFixed(1);
        cpuGauge.classList.toggle('is-oc', smoothCpuClk >= 3500);
    }
    const cpuTempGauge = document.getElementById('c2-cpu-temp-gauge');
    if (cpuTempGauge) {
        const smoothTemp = Math.min(100, Math.max(20, smooth('cpuDieTemp', cpuDie, SMOOTHING_CRISP)));
        const tempOffset = Math.max(0, 257.6 - ((smoothTemp - 20) / 80) * 257.6);
        cpuTempGauge.style.strokeDashoffset = tempOffset.toFixed(1);
        cpuTempGauge.classList.toggle('is-hot', smoothTemp >= 75);
        cpuTempGauge.classList.toggle('is-cool', smoothTemp < 50);
    }
    const cpuLoadGauge = document.getElementById('c2-cpu-load-gauge');
    if (cpuLoadGauge) {
        const smoothLoad = Math.min(100, Math.max(0, smooth('cpuLoad', cpuLoad, SMOOTHING_CRISP)));
        const cpuLoadOffset = Math.max(0, 257.6 - (smoothLoad / 100) * 257.6);
        cpuLoadGauge.style.strokeDashoffset = cpuLoadOffset.toFixed(1);
        cpuLoadGauge.classList.toggle('is-high', smoothLoad >= 90);
        cpuLoadGauge.classList.toggle('is-mid', smoothLoad >= 60 && smoothLoad < 90);
    }
    const isCpuOc = smoothCpuClk >= 3500;
    const cpuFreqEl = document.getElementById('v2-cpu-freq');
    const cpuTagEl = document.getElementById('v2-cpu-die-tag');
    if (cpuGauge) cpuGauge.classList.toggle('gauge-oc-glow', isCpuOc);
    if (cpuFreqEl) cpuFreqEl.classList.toggle('val-oc-glow', isCpuOc);
    if (cpuTagEl) {
        if (isCpuOc) {
            cpuTagEl.innerHTML = '<span class="oc-tag-fire">🔥 Overclock Active</span>';
        } else {
            cpuTagEl.textContent = '● Nominal Thermal Band';
        }
    }

    setText('v2-cpu-vin', smooth('cpuVin', cpuVin).toFixed(2));
    setBar('v2-cpu-vin-bar', cpuVin);
    setText('v2-cpu-vout', smooth('cpuVout', cpuVout).toFixed(3));
    setText('v2-cpu-basic-vout', smooth('cpuVout', cpuVout).toFixed(3) + ' V');
    setBar('v2-cpu-vout-bar', cpuVout);
    setText('v2-cpu-iout', smooth('cpuIout', cpuIout).toFixed(1));
    setBar('v2-cpu-iout-bar', cpuIout);
    setFaultBadge('v2-cpu-iout-fault-badge', cpuIoutWarning, cpuIoutFault, 'over-current (STATUS_IOUT)');
    const cpuPVal = smooth('cpuPoutTxt', cpuPout);
    setText('v2-cpu-pout', cpuPVal.toFixed(1));
    setText('v2-cpu-basic-pout', cpuPVal.toFixed(1) + ' W');
    setBar('v2-cpu-pout-bar', cpuPout);
    const cpuTVal = smooth('cpuT', cpuT, SMOOTHING_CRISP);
    setText('v2-cpu-vrmtemp', cpuTVal.toFixed(0));
    setText('v2-cpu-basic-vrmtemp', cpuTVal.toFixed(0) + ' °C');
    setBar('v2-cpu-vrmtemp-bar', cpuTVal);
    setStatusClass('v2-cpu-vrmtemp-figure', cpuTVal, TEMP_THRESH.vrm);
    setStatusClass('v2-cpu-vrmtemp-bar', cpuTVal, TEMP_THRESH.vrm);
    setFaultBadge('v2-cpu-temp-fault-badge', cpuTempWarning, cpuTempFault, 'over-temperature (STATUS_TEMPERATURE)');

    // --- GPU CORE ---
    setText('v2-gpu-die', gpuDie.toFixed(1));
    setStatusClass('v2-gpu-die-unit', gpuDie, TEMP_THRESH.die);
    const gpuLoad = typeof sw.gpu_busy_pct === 'number' ? sw.gpu_busy_pct : 98;
    setText('v2-gpu-load', Math.round(smooth('gpuLoad', gpuLoad, SMOOTHING_CRISP)).toString());
    const smoothGpuClk = smooth('gpuClock', gpuClock);
    setText('v2-gpu-clock', Math.round(smoothGpuClk).toString());
    const gpuGauge = document.getElementById('c2-gpu-gauge');
    if (gpuGauge) {
        const gpuOffset = Math.max(0, 257.6 - (smoothGpuClk / 2000) * 257.6);
        gpuGauge.style.strokeDashoffset = gpuOffset.toFixed(1);
        gpuGauge.classList.toggle('is-oc', smoothGpuClk >= 1500);
    }
    const gpuTempGauge = document.getElementById('c2-gpu-temp-gauge');
    if (gpuTempGauge) {
        const smoothTemp = Math.min(100, Math.max(20, smooth('gpuDieTemp', gpuDie, SMOOTHING_CRISP)));
        const tempOffset = Math.max(0, 257.6 - ((smoothTemp - 20) / 80) * 257.6);
        gpuTempGauge.style.strokeDashoffset = tempOffset.toFixed(1);
        gpuTempGauge.classList.toggle('is-hot', smoothTemp >= 75);
        gpuTempGauge.classList.toggle('is-cool', smoothTemp < 50);
    }
    const gpuLoadGauge = document.getElementById('c2-gpu-load-gauge');
    if (gpuLoadGauge) {
        const smoothGpuLd = Math.min(100, Math.max(0, smooth('gpuLoad', gpuLoad, SMOOTHING_CRISP)));
        const gpuLoadOffset = Math.max(0, 257.6 - (smoothGpuLd / 100) * 257.6);
        gpuLoadGauge.style.strokeDashoffset = gpuLoadOffset.toFixed(1);
        gpuLoadGauge.classList.toggle('is-high', smoothGpuLd >= 90);
        gpuLoadGauge.classList.toggle('is-mid', smoothGpuLd >= 60 && smoothGpuLd < 90);
    }
    const isGpuOc = smoothGpuClk >= 1500;
    const gpuClockEl = document.getElementById('v2-gpu-clock');
    const gpuTagEl = document.getElementById('v2-gpu-die-tag');
    if (gpuGauge) gpuGauge.classList.toggle('gauge-oc-glow-gpu', isGpuOc);
    if (gpuClockEl) gpuClockEl.classList.toggle('val-oc-glow-gpu', isGpuOc);
    if (gpuTagEl) {
        if (isGpuOc) {
            gpuTagEl.innerHTML = '<span class="oc-tag-fire">🔥 Overclock Active</span>';
        } else {
            gpuTagEl.textContent = '● Optimal Junction';
        }
    }

    setText('v2-gpu-vin', smooth('gpuVin', gpuVin).toFixed(2));
    setBar('v2-gpu-vin-bar', gpuVin);
    setText('v2-gpu-vout', smooth('gpuVout', gpuVout).toFixed(3));
    setText('v2-gpu-basic-vout', smooth('gpuVout', gpuVout).toFixed(3) + ' V');
    setBar('v2-gpu-vout-bar', gpuVout);
    setText('v2-gpu-iout', smooth('gpuIout', gpuIout).toFixed(1));
    setBar('v2-gpu-iout-bar', gpuIout);
    setFaultBadge('v2-gpu-iout-fault-badge', gpuIoutWarning, gpuIoutFault, 'over-current (STATUS_IOUT)');
    const gpuPVal = smooth('gpuPoutTxt', gpuPout);
    setText('v2-gpu-pout', gpuPVal.toFixed(1));
    setText('v2-gpu-basic-pout', gpuPVal.toFixed(1) + ' W');
    setBar('v2-gpu-pout-bar', gpuPout);
    const gpuTVal = smooth('gpuT', gpuT, SMOOTHING_CRISP);
    setText('v2-gpu-vrmtemp', gpuTVal.toFixed(0));
    setText('v2-gpu-basic-vrmtemp', gpuTVal.toFixed(0) + ' °C');
    setBar('v2-gpu-vrmtemp-bar', gpuTVal);
    setStatusClass('v2-gpu-vrmtemp-figure', gpuTVal, TEMP_THRESH.vrm);
    setStatusClass('v2-gpu-vrmtemp-bar', gpuTVal, TEMP_THRESH.vrm);
    setFaultBadge('v2-gpu-temp-fault-badge', gpuTempWarning, gpuTempFault, 'over-temperature (STATUS_TEMPERATURE)');

}

let pollTimer = null;
function scheduleNextPoll(delay = 700) {
    if (pollTimer) clearTimeout(pollTimer);
    const interval = (typeof document !== 'undefined' && document.hidden) ? 3000 : delay;
    pollTimer = setTimeout(fetchTelemetry, interval);
}

if (typeof document !== 'undefined') {
    document.addEventListener('visibilitychange', () => {
        if (!document.hidden) fetchTelemetry();
    });
}

async function fetchTelemetry() {
    try {
        const controller = typeof AbortController !== 'undefined' ? new AbortController() : null;
        const timeoutId = controller ? setTimeout(() => controller.abort(), 2500) : null;
        const response = await fetch('/api/telemetry', controller ? { signal: controller.signal } : {});
        if (timeoutId) clearTimeout(timeoutId);
        const data = await response.json();
        if (!response.ok || !data || data.error) throw new Error(data?.error || 'Telemetry request failed');
        latest = data;
        frameReady = true;
        latestReceivedAt = performance.now();
        telemetryFetchFailed = false;
    } catch (error) {
        telemetryFetchFailed = true;
        console.error('Failed to fetch telemetry:', error);
    } finally {
        scheduleNextPoll(700);
    }
}

fetchTelemetry();

// Core/CU counts, unlike temp/clock/power, only change on a reboot (CPU) or
// a live WGP toggle (GPU) — not worth polling every 700ms, so this is a
// separate, once-per-page-load fetch rather than part of the telemetry loop.
async function fetchTopology() {
    try {
        const response = await fetch('/api/topology');
        const topo = await response.json();

        const hasCoreCount = typeof topo.cpu_physical_cores === 'number' && topo.cpu_physical_cores > 0;
        setDisplay('v2-cpu-cores-badge', hasCoreCount);
        if (hasCoreCount) {
            const cores = topo.cpu_physical_cores;
            const threads = topo.cpu_logical_cores || (cores * 2);
            setText('v2-cpu-cores', String(cores));
            setText('v2-cpu-threads', String(threads));
            setCoreBadgeClass('v2-cpu-cores-badge', topo.cpu_physical_cores, 6, 8);
        }

        const hasCuCount = typeof topo.gpu_cu_active === 'number' && topo.gpu_cu_active > 0;
        setDisplay('v2-gpu-cus-badge', hasCuCount);
        if (hasCuCount) {
            setText('v2-gpu-cus', String(topo.gpu_cu_active));
            setCoreBadgeClass('v2-gpu-cus-badge', topo.gpu_cu_active, 24, 40);
        }
    } catch (error) {
        console.error('Failed to fetch topology:', error);
    }
}
fetchTopology();

// Overclock config/service state — same once-per-page-load cadence as
// topology: an OC file edit or a service (de)activation isn't something
// that needs 700ms polling.
function setOcPanel(panelId, dotId, active, configPresent, valueIds) {
    setDisplay(panelId, configPresent);
    if (!configPresent) return;
    const dotEl = document.getElementById(dotId);
    if (dotEl) {
        dotEl.classList.toggle('active', active);
        dotEl.title = active ? 'Active' : 'Inactive';
    }
    const panel = document.getElementById(panelId);
    if (panel) panel.classList.toggle('oc-inactive', !active);
    valueIds.forEach(([id, value]) => setText(id, value == null ? '—' : String(value)));
}

async function fetchOverclock() {
    try {
        const response = await fetch('/api/overclock');
        const oc = await response.json();

        setOcPanel('v2-cpu-oc-panel', 'v2-cpu-oc-dot', oc.cpu?.active, oc.cpu?.config_present, [
            ['v2-cpu-oc-freq-val', oc.cpu?.target_freq_mhz],
            ['v2-cpu-basic-oc', oc.cpu?.target_freq_mhz ? (oc.cpu.target_freq_mhz + ' MHz') : '3800 MHz'],
            ['v2-cpu-oc-maxtemp', oc.cpu?.max_temp_c],
        ]);
        const cpuTargetEl = document.getElementById('v2-cpu-oc-target-val');
        if (cpuTargetEl && (oc.cpu?.target_freq_mhz >= 3500)) {
            cpuTargetEl.classList.add('oc-val-highlight');
        }

        setOcPanel('v2-gpu-oc-panel', 'v2-gpu-oc-dot', oc.gpu?.active, oc.gpu?.config_present, [
            ['v2-gpu-oc-maxfreq', oc.gpu?.max_freq_mhz],
            ['v2-gpu-basic-maxfreq', oc.gpu?.max_freq_mhz ? (oc.gpu.max_freq_mhz + ' MHz') : '1900 MHz'],
            ['v2-gpu-oc-minfreq', oc.gpu?.min_freq_mhz],
        ]);
        const gpuMaxEl = document.getElementById('v2-gpu-oc-max-val');
        if (gpuMaxEl && (oc.gpu?.max_freq_mhz >= 1500)) {
            gpuMaxEl.classList.add('oc-val-highlight');
        }
    } catch (error) {
        console.error('Failed to fetch overclock state:', error);
    }
}
fetchOverclock();

function renderLoop() {
    updateUI();
    setTimeout(() => requestAnimationFrame(renderLoop), 50);
}
requestAnimationFrame(renderLoop);
