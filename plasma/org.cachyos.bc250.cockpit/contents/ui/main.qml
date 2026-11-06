import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Disable default plasma frame to render our custom cyber glass aesthetic
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Live Telemetry Properties
    property real cpuDieTemp: 52.0
    property int cpuFreqMhz: 1146
    property real cpuUsagePct: 15.0
    property int cpuTargetFreqMhz: 3500

    property real gpuDieTemp: 51.0
    property int gpuSclkMhz: 700
    property real gpuBusyPct: 14.0
    property int gpuMaxFreqMhz: 1850

    property real vramHotspotTemp: 56.0
    property int vramHotspotChip: 0
    property var memoryChips: [54, 56, 50, 52, 50, 54, 50, 46]

    property real vrmTemp: 61.0
    property real totalPowerW: 118.0
    property real railVin: 12.10
    property int fanRpm: 1820
    property string kernelRelease: "7.3.1-1.401"

    // Representations
    compactRepresentation: TaskbarPillView {}

    fullRepresentation: Item {
        id: fullRepContainer
        implicitWidth: currentLoader.implicitWidth
        implicitHeight: currentLoader.implicitHeight

        Loader {
            id: currentLoader
            anchors.fill: parent
            sourceComponent: {
                if (Plasmoid.formFactor === PlasmaCore.Types.Planar) {
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

    preferredRepresentation: (Plasmoid.formFactor === PlasmaCore.Types.Planar) ? fullRepresentation : compactRepresentation

    // Polling Telemetry Data via XMLHttpRequest
    Timer {
        id: telemetryTimer
        interval: Math.max(250, Plasmoid.configuration.pollInterval || 700)
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
        }
    }

    function fetchTelemetry() {
        var xhr = new XMLHttpRequest();
        var url = (Plasmoid.configuration.serverUrl || "http://127.0.0.1:8090") + "/api/telemetry";
        xhr.open("GET", url, true);
        xhr.timeout = 1500;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        if (data.software) {
                            if (typeof data.software.cpu_temp_c === "number") root.cpuDieTemp = data.software.cpu_temp_c;
                            if (typeof data.software.cpu_freq_mhz === "number") root.cpuFreqMhz = Math.round(data.software.cpu_freq_mhz);
                            if (typeof data.software.cpu_usage_pct === "number") root.cpuUsagePct = data.software.cpu_usage_pct;
                            if (typeof data.software.gpu_temp_c === "number") root.gpuDieTemp = data.software.gpu_temp_c;
                            if (typeof data.software.gpu_sclk_mhz === "number") root.gpuSclkMhz = Math.round(data.software.gpu_sclk_mhz);
                            if (typeof data.software.gpu_busy_pct === "number") root.gpuBusyPct = data.software.gpu_busy_pct;
                        }

                        if (data.hardware) {
                            var cpuVrm = (data.hardware.cpu && data.hardware.cpu.temp) ? data.hardware.cpu.temp : 50;
                            var gpuVrm = (data.hardware.gpu && data.hardware.gpu.temp) ? data.hardware.gpu.temp : 54;
                            root.vrmTemp = Math.max(cpuVrm, gpuVrm);

                            if (typeof data.hardware.total_power === "number") {
                                root.totalPowerW = Math.max(30, data.hardware.total_power);
                            }
                            if (data.hardware.cpu && typeof data.hardware.cpu.vin === "number") {
                                root.railVin = data.hardware.cpu.vin;
                            }
                        }

                        if (data.cooling && typeof data.cooling.fan_rpm === "number") {
                            root.fanRpm = data.cooling.fan_rpm;
                        }

                        if (data.memory && data.memory.chips_c && data.memory.chips_c.length >= 8) {
                            root.memoryChips = data.memory.chips_c;
                            if (typeof data.memory.hotspot_c === "number") root.vramHotspotTemp = data.memory.hotspot_c;
                            if (typeof data.memory.hotspot_chip === "number") root.vramHotspotChip = data.memory.hotspot_chip;
                        }
                    } catch (e) {
                        // ignore JSON parse errors during quick polls
                    }
                }
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

    Component.onCompleted: {
        // Read kernel version string once
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file:///proc/sys/kernel/osrelease", true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                root.kernelRelease = xhr.responseText.trim();
            }
        };
        try { xhr.send(); } catch (e) {}
    }
}
