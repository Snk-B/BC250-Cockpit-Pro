import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Disable default frame so custom cyberpunk glass fills the container
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Bundled Cyberpunk Telemetry Typeface (JetBrains Mono)
    FontLoader { id: fontJbRegular; source: "fonts/JetBrainsMono-Regular.ttf" }
    FontLoader { id: fontJbMedium; source: "fonts/JetBrainsMono-Medium.ttf" }
    FontLoader { id: fontJbBold; source: "fonts/JetBrainsMono-Bold.ttf" }
    FontLoader { id: fontJbExtraBold; source: "fonts/JetBrainsMono-ExtraBold.ttf" }

    readonly property string monoFont: "JetBrains Mono"


    // Target dimensions depending on layout
    readonly property bool isPlanar: (Plasmoid.formFactor === PlasmaCore.Types.Planar)
    readonly property bool isHorizontalDock: (isPlanar && Plasmoid.configuration.desktopLayout === 1)

    // Language Detection:
    // If Plasmoid.configuration.language === "pt" -> Portuguese
    // If Plasmoid.configuration.language === "en" -> English
    // If "auto" (default):
    // Only display Portuguese if the system UI locale is Portuguese (pt_BR, pt_PT, pt).
    // If system is in English or any other language -> strictly English.
    readonly property bool isPortuguese: {
        var cfg = (Plasmoid.configuration.language || "auto");
        if (cfg === "pt") return true;
        if (cfg === "en") return false;

        // Auto mode: check system UI languages
        try {
            var uiLangs = Qt.locale().uiLanguages;
            if (uiLangs && uiLangs.length > 0) {
                for (var i = 0; i < uiLangs.length; i++) {
                    var lang = (uiLangs[i] || "").toLowerCase().replace("_", "-");
                    if (lang.indexOf("pt") === 0) return true;
                    if (i === 0 && lang.indexOf("en") === 0) return false;
                }
            }
        } catch (e) {}

        var loc = (Qt.locale().name || "").toLowerCase().replace("_", "-");
        if (loc.indexOf("pt") === 0) return true;
        return false;
    }

    // Panel representation width calculation - 100% FIXED to prevent any taskbar jitter
    readonly property real panelPillWidth: 352

    implicitWidth: isPlanar ? (isHorizontalDock ? 500 : 280) : panelPillWidth
    implicitHeight: isPlanar ? (isHorizontalDock ? 76 : 420) : 36

    // Flexible responsive bounds when on desktop, fixed when in taskbar panel
    Layout.minimumWidth: isPlanar ? (isHorizontalDock ? 460 : 280) : panelPillWidth
    Layout.preferredWidth: implicitWidth
    Layout.maximumWidth: isPlanar ? (isHorizontalDock ? 540 : 280) : panelPillWidth

    Layout.minimumHeight: isPlanar ? (isHorizontalDock ? 76 : 420) : implicitHeight
    Layout.preferredHeight: implicitHeight
    Layout.maximumHeight: isPlanar ? (isHorizontalDock ? 76 : 420) : implicitHeight

    Layout.fillWidth: false
    Layout.fillHeight: false

    width: implicitWidth
    height: implicitHeight

    onIsHorizontalDockChanged: {
        root.width = isHorizontalDock ? 500 : 280;
        root.height = isHorizontalDock ? 76 : 420;
    }

    // Hardware Topology (Dynamic CUs and Shaders)
    property int gpuCuActive: 40
    property int gpuShaders: gpuCuActive * 64

    // Raw incoming data
    property real rawCpuDieTemp: 52.0
    property real rawGpuDieTemp: 51.0
    property real rawVramHotspotTemp: 56.0
    property real rawVrmTemp: 61.0
    property real rawCpuFreqMhz: 1146
    property real rawGpuSclkMhz: 700
    property real rawCpuUsagePct: 15.0
    property real rawGpuBusyPct: 14.0
    property real rawTotalPowerW: 35.0
    property real rawFanRpm: 1820
    property real rawFanPwmPct: 30.0
    property real rawVin12v: 12.09

    // Voltage & Power Delivery Telemetry
    property real rawCpuVin: 12.08
    property real rawCpuVout: 1.004
    property real rawCpuIout: 3.5
    property real rawCpuPout: 3.5
    property real rawCpuVrmTemp: 49.0

    property real rawGpuVin: 12.09
    property real rawGpuVout: 0.697
    property real rawGpuIout: 10.0
    property real rawGpuPout: 7.0
    property real rawGpuVrmTemp: 53.0

    // Live Frequency Histories for Oscilloscope Sparklines
    property var cpuFreqHistory: [1100, 1120, 1140, 1130, 1150, 1146, 1140, 1146, 1152, 1148, 1146, 1140, 1146, 1146, 1142, 1146]
    property var gpuFreqHistory: [680, 690, 700, 700, 695, 700, 710, 705, 700, 700, 705, 700, 700, 700, 695, 700]
    property var cpuLoadHistory: [12, 14, 15, 13, 16, 18, 15, 14, 15, 17, 16, 15, 14, 15, 16, 15]
    property var gpuLoadHistory: [10, 12, 14, 14, 13, 15, 16, 14, 12, 14, 15, 14, 13, 14, 15, 14]

    // Smooth Animated Properties (100% Mathematical match to BC250-Cockpit-Pro/web/app.js)
    readonly property real smoothingFactor: 0.08       // For clocks, power, voltages (SMOOTHING)
    readonly property real smoothingCrispFactor: 0.20  // For temps, loads, fans (SMOOTHING_CRISP)

    property var smoothState: ({})

    function smooth(key, targetValue, factor) {
        if (typeof targetValue !== "number" || isNaN(targetValue)) return 0.0;
        var s = smoothState[key];
        if (s === undefined) {
            smoothState[key] = targetValue;
            return targetValue;
        }
        var diff = targetValue - s;
        if (Math.abs(diff) < 0.0005) {
            smoothState[key] = targetValue;
        } else {
            smoothState[key] = s + diff * factor;
        }
        return smoothState[key];
    }

    property real smoothCpuDieTemp: rawCpuDieTemp
    property real smoothGpuDieTemp: rawGpuDieTemp
    property real smoothVramHotspotTemp: rawVramHotspotTemp
    property real smoothVrmTemp: rawVrmTemp

    property real smoothCpuFreqMhz: rawCpuFreqMhz
    property real smoothGpuSclkMhz: rawGpuSclkMhz

    property real smoothCpuUsagePct: rawCpuUsagePct
    property real smoothGpuBusyPct: rawGpuBusyPct

    property real smoothTotalPowerW: rawTotalPowerW
    property real smoothFanRpm: rawFanRpm
    property real smoothFanPwmPct: rawFanPwmPct
    property real smoothVin12v: rawVin12v

    property real smoothCpuVin: rawCpuVin
    property real smoothCpuVout: rawCpuVout
    property real smoothCpuIout: rawCpuIout
    property real smoothCpuPout: rawCpuPout
    property real smoothCpuVrmTemp: rawCpuVrmTemp

    property real smoothGpuVin: rawGpuVin
    property real smoothGpuVout: rawGpuVout
    property real smoothGpuIout: rawGpuIout
    property real smoothGpuPout: rawGpuPout
    property real smoothGpuVrmTemp: rawGpuVrmTemp

    // 50ms Render Loop (20 FPS EMA Decay - Identical to web renderLoop)
    Timer {
        id: smoothRenderTimer
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            root.smoothCpuDieTemp = root.smooth("cpuDie", root.rawCpuDieTemp, root.smoothingCrispFactor);
            root.smoothGpuDieTemp = root.smooth("gpuDie", root.rawGpuDieTemp, root.smoothingCrispFactor);
            root.smoothVramHotspotTemp = root.smooth("vramHotspot", root.rawVramHotspotTemp, root.smoothingCrispFactor);
            root.smoothVrmTemp = root.smooth("vrmTemp", root.rawVrmTemp, root.smoothingCrispFactor);

            root.smoothCpuFreqMhz = root.smooth("cpuFreq", root.rawCpuFreqMhz, root.smoothingFactor);
            root.smoothGpuSclkMhz = root.smooth("gpuSclk", root.rawGpuSclkMhz, root.smoothingFactor);

            root.smoothCpuUsagePct = root.smooth("cpuLoad", root.rawCpuUsagePct, root.smoothingCrispFactor);
            root.smoothGpuBusyPct = root.smooth("gpuLoad", root.rawGpuBusyPct, root.smoothingCrispFactor);

            root.smoothTotalPowerW = root.smooth("totalPower", root.rawTotalPowerW, root.smoothingFactor);
            root.smoothFanRpm = root.smooth("fanRpm", root.rawFanRpm, root.smoothingCrispFactor);
            root.smoothFanPwmPct = root.smooth("fanPwmPct", root.rawFanPwmPct, root.smoothingCrispFactor);
            root.smoothVin12v = root.smooth("vin12v", root.rawVin12v, root.smoothingFactor);

            root.smoothCpuVin = root.smooth("cpuVin", root.rawCpuVin, root.smoothingFactor);
            root.smoothCpuVout = root.smooth("cpuVout", root.rawCpuVout, root.smoothingFactor);
            root.smoothCpuIout = root.smooth("cpuIout", root.rawCpuIout, root.smoothingFactor);
            root.smoothCpuPout = root.smooth("cpuPout", root.rawCpuPout, root.smoothingFactor);
            root.smoothCpuVrmTemp = root.smooth("cpuVrmTemp", root.rawCpuVrmTemp, root.smoothingCrispFactor);

            root.smoothGpuVin = root.smooth("gpuVin", root.rawGpuVin, root.smoothingFactor);
            root.smoothGpuVout = root.smooth("gpuVout", root.rawGpuVout, root.smoothingFactor);
            root.smoothGpuIout = root.smooth("gpuIout", root.rawGpuIout, root.smoothingFactor);
            root.smoothGpuPout = root.smooth("gpuPout", root.rawGpuPout, root.smoothingFactor);
            root.smoothGpuVrmTemp = root.smooth("gpuVrmTemp", root.rawGpuVrmTemp, root.smoothingCrispFactor);
        }
    }

    // Configuration / Clocks targets
    property int cpuTargetFreqMhz: 3500
    property int gpuMaxFreqMhz: 1850
    property int vramHotspotChip: 0
    property var memoryChips: [54, 56, 50, 52, 50, 54, 50, 46]
    property string kernelRelease: "7.4.0-rc1"

    // Dynamic Kernel Release & Flavor Detector (100% dynamic, never hardcoded)
    readonly property string dynamicKernelBadge: {
        if (!root.kernelRelease) return "CACHYOS";
        var rel = root.kernelRelease.toLowerCase();
        var ver = root.kernelRelease.split("-")[0];
        if (root.kernelRelease.indexOf("-rc") !== -1) {
            var m = root.kernelRelease.match(/-rc\d+/i);
            if (m) ver += m[0];
        }

        var flavor = "KERNEL";
        if (rel.indexOf("cachyos") !== -1) {
            if (rel.indexOf("rc-bc250") !== -1 || rel.indexOf("rc") !== -1) flavor = "CACHYOS RC";
            else if (rel.indexOf("bore") !== -1) flavor = "CACHYOS BORE";
            else if (rel.indexOf("lto") !== -1) flavor = "CACHYOS LTO";
            else if (rel.indexOf("sched-ext") !== -1 || rel.indexOf("scx") !== -1) flavor = "CACHYOS SCX";
            else flavor = "CACHYOS";
        } else if (rel.indexOf("zen") !== -1) {
            flavor = "ZEN";
        } else if (rel.indexOf("arch") !== -1) {
            flavor = "ARCH";
        }
        return flavor + " \u00B7 " + ver;
    }

    // Context Menu Actions (Right-click on widget)
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: (Plasmoid.configuration.desktopLayout === 1) ? 
                  (root.isPortuguese ? "Alternar para Desktop HUD (Completo)" : "Switch to Desktop HUD (Full)") : 
                  (root.isPortuguese ? "Alternar para Dock Horizontal (Compacto)" : "Switch to Horizontal Dock (Compact)")
            icon.name: (Plasmoid.configuration.desktopLayout === 1) ? "view-dashboard" : "view-paged"
            visible: root.isPlanar
            onTriggered: {
                Plasmoid.configuration.desktopLayout = (Plasmoid.configuration.desktopLayout === 1) ? 0 : 1;
            }
        },
        PlasmaCore.Action {
            text: root.isPortuguese ? "Idioma: Português (Mudar para English)" : "Language: English (Switch to Português)"
            icon.name: "preferences-desktop-locale"
            onTriggered: {
                Plasmoid.configuration.language = root.isPortuguese ? "en" : "pt";
            }
        },
        PlasmaCore.Action {
            text: root.isPortuguese ? "Abrir Cockpit Pro Web" : "Open Cockpit Pro Web"
            icon.name: "globe"
            onTriggered: {
                Qt.openUrlExternally("http://localhost:8090/");
            }
        }
    ]

    // Compact Representation (Taskbar Pill)
    compactRepresentation: TaskbarPillView {
        id: compactPill
    }

    // Full Representation (Desktop HUD / Dock or Tray Flyout Popup)
    fullRepresentation: Item {
        id: fullRepContainer
        Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

        Layout.minimumWidth: root.isPlanar ? (root.isHorizontalDock ? 500 : 280) : 420
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: root.isPlanar ? (root.isHorizontalDock ? 500 : 280) : 420

        Layout.minimumHeight: root.isPlanar ? (root.isHorizontalDock ? 76 : 420) : 460
        Layout.preferredHeight: Layout.minimumHeight
        Layout.maximumHeight: root.isPlanar ? (root.isHorizontalDock ? 76 : 420) : 460

        implicitWidth: Layout.preferredWidth
        implicitHeight: Layout.preferredHeight
        width: Layout.preferredWidth
        height: Layout.preferredHeight

        Loader {
            id: currentLoader
            anchors.fill: parent
            sourceComponent: {
                if (root.isPlanar) {
                    return (Plasmoid.configuration.desktopLayout === 1) ? horizontalDockComponent : desktopHudComponent;
                } else {
                    return trayFlyoutComponent;
                }
            }
        }
    }

    Component { id: desktopHudComponent; DesktopHudView {} }
    Component { id: horizontalDockComponent; HorizontalDockView {} }
    Component { id: trayFlyoutComponent; TrayFlyoutView {} }

    preferredRepresentation: isPlanar ? fullRepresentation : compactRepresentation

    // Polling Telemetry Data via XMLHttpRequest (Smooth 1000ms cadence like Web Dashboard)
    Timer {
        id: telemetryTimer
        interval: Math.max(300, Plasmoid.configuration.pollInterval || 700)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            fetchTelemetry();
        }
    }

    // Config / Topology Polling (every 5 seconds)
    Timer {
        id: configTimer
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            fetchOverclock();
            fetchTopology();
        }
    }

    function fetchTelemetry() {
        var xhr = new XMLHttpRequest();
        var url = (Plasmoid.configuration.serverUrl || "http://127.0.0.1:8090") + "/api/telemetry";
        xhr.open("GET", url, true);
        xhr.timeout = 1500;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    if (data.software) {
                        if (typeof data.software.cpu_temp_c === "number") root.rawCpuDieTemp = data.software.cpu_temp_c;
                        if (typeof data.software.cpu_freq_mhz === "number") {
                            root.rawCpuFreqMhz = data.software.cpu_freq_mhz;
                            var cpuArr = root.cpuFreqHistory.slice();
                            cpuArr.push(data.software.cpu_freq_mhz);
                            if (cpuArr.length > 24) cpuArr.shift();
                            root.cpuFreqHistory = cpuArr;
                        }
                        if (typeof data.software.cpu_usage_pct === "number") {
                            root.rawCpuUsagePct = data.software.cpu_usage_pct;
                            var cLoad = root.cpuLoadHistory.slice();
                            cLoad.push(data.software.cpu_usage_pct);
                            if (cLoad.length > 20) cLoad.shift();
                            root.cpuLoadHistory = cLoad;
                        }
                        if (typeof data.software.gpu_temp_c === "number") root.rawGpuDieTemp = data.software.gpu_temp_c;
                        if (typeof data.software.gpu_sclk_mhz === "number") {
                            root.rawGpuSclkMhz = data.software.gpu_sclk_mhz;
                            var gpuArr = root.gpuFreqHistory.slice();
                            gpuArr.push(data.software.gpu_sclk_mhz);
                            if (gpuArr.length > 24) gpuArr.shift();
                            root.gpuFreqHistory = gpuArr;
                        }
                        if (typeof data.software.gpu_busy_pct === "number") {
                            root.rawGpuBusyPct = data.software.gpu_busy_pct;
                            var gLoad = root.gpuLoadHistory.slice();
                            gLoad.push(data.software.gpu_busy_pct);
                            if (gLoad.length > 20) gLoad.shift();
                            root.gpuLoadHistory = gLoad;
                        }
                    }

                    if (data.hardware) {
                        if (data.hardware.cpu) {
                            if (typeof data.hardware.cpu.vout === "number") root.rawCpuVout = data.hardware.cpu.vout;
                            if (typeof data.hardware.cpu.iout === "number") root.rawCpuIout = data.hardware.cpu.iout;
                            if (typeof data.hardware.cpu.pout === "number") root.rawCpuPout = data.hardware.cpu.pout;
                            if (typeof data.hardware.cpu.vin === "number") {
                                root.rawCpuVin = data.hardware.cpu.vin;
                                root.rawVin12v = data.hardware.cpu.vin;
                            }
                            if (typeof data.hardware.cpu.temp === "number") root.rawCpuVrmTemp = data.hardware.cpu.temp;
                        }
                        if (data.hardware.gpu) {
                            if (typeof data.hardware.gpu.vout === "number") root.rawGpuVout = data.hardware.gpu.vout;
                            if (typeof data.hardware.gpu.iout === "number") root.rawGpuIout = data.hardware.gpu.iout;
                            if (typeof data.hardware.gpu.pout === "number") root.rawGpuPout = data.hardware.gpu.pout;
                            if (typeof data.hardware.gpu.vin === "number") root.rawGpuVin = data.hardware.gpu.vin;
                            if (typeof data.hardware.gpu.temp === "number") root.rawGpuVrmTemp = data.hardware.gpu.temp;
                        }

                        root.rawVrmTemp = Math.max(root.rawCpuVrmTemp, root.rawGpuVrmTemp);

                        // True SMU PPT Total Power from AMDGPU SMU (matching Cockpit Pro Web Dashboard)
                        if (data.software && typeof data.software.gpu_ppt_w === "number" && data.software.gpu_ppt_w > 0) {
                            root.rawTotalPowerW = data.software.gpu_ppt_w;
                        } else if (typeof data.hardware.total_power === "number" && data.hardware.total_power > 0) {
                            root.rawTotalPowerW = data.hardware.total_power;
                        }
                    }

                    if (data.cooling) {
                        if (typeof data.cooling.fan_rpm === "number") {
                            root.rawFanRpm = data.cooling.fan_rpm;
                        }
                        if (typeof data.cooling.fan_pwm_pct === "number") {
                            root.rawFanPwmPct = data.cooling.fan_pwm_pct;
                        }
                    }

                    if (data.memory && data.memory.chips_c && data.memory.chips_c.length >= 8) {
                        root.memoryChips = data.memory.chips_c;
                        if (typeof data.memory.hotspot_c === "number") root.rawVramHotspotTemp = data.memory.hotspot_c;
                        if (typeof data.memory.hotspot_chip === "number") root.vramHotspotChip = data.memory.hotspot_chip;
                    }
                } catch (e) {}
            }
        };
        xhr.send();
    }

    function fetchOverclock() {
        var xhr = new XMLHttpRequest();
        var url = (Plasmoid.configuration.serverUrl || "http://127.0.0.1:8090") + "/api/overclock";
        xhr.open("GET", url, true);
        xhr.timeout = 3000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    if (data.cpu && typeof data.cpu.target_freq_mhz === "number") {
                        root.cpuTargetFreqMhz = data.cpu.target_freq_mhz;
                    }
                    if (data.gpu && typeof data.gpu.max_freq_mhz === "number") {
                        root.gpuMaxFreqMhz = data.gpu.max_freq_mhz;
                    }
                } catch (e) {}
            }
        };
        xhr.send();
    }

    function fetchTopology() {
        var xhr = new XMLHttpRequest();
        var url = (Plasmoid.configuration.serverUrl || "http://127.0.0.1:8090") + "/api/topology";
        xhr.open("GET", url, true);
        xhr.timeout = 3000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    if (data.kernel_release) {
                        root.kernelRelease = data.kernel_release;
                    }
                    if (typeof data.gpu_cu_active === "number" && data.gpu_cu_active > 0) {
                        root.gpuCuActive = data.gpu_cu_active;
                    }
                } catch (e) {}
            }
        };
        xhr.send();
    }

    Component.onCompleted: {
        fetchTopology();
    }
}
