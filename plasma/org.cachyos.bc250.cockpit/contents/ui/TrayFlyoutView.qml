import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: flyoutRoot
    implicitWidth: 420
    implicitHeight: 460
    width: 420
    height: 460

    Layout.minimumWidth: 420
    Layout.preferredWidth: 420
    Layout.maximumWidth: 420

    Layout.minimumHeight: 460
    Layout.preferredHeight: 460
    Layout.maximumHeight: 460

    // Outer Cyberpunk HUD Card (matching Concept 3 GitHub visual design)
    Rectangle {
        id: flyoutBg
        anchors.fill: parent
        color: "#0a101a"
        radius: 10
        border.color: "#1c3d36"
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // Header
            RowLayout {
                Layout.fillWidth: true

                RowLayout {
                    spacing: 8

                    // Native Vector 3-Stacked Rhombuses Icon (Concept 3 Brand Icon - Never fails or shows missing 'X')
                    Canvas {
                        id: brandIcon
                        implicitWidth: 18
                        implicitHeight: 18
                        renderTarget: Canvas.Image

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = "#00f0a8";
                            ctx.lineWidth = 1.4;
                            ctx.lineJoin = "round";
                            ctx.lineCap = "round";

                            // Top Rhombus Layer
                            ctx.beginPath();
                            ctx.moveTo(9, 2.5);
                            ctx.lineTo(16, 5.5);
                            ctx.lineTo(9, 8.5);
                            ctx.lineTo(2, 5.5);
                            ctx.closePath();
                            ctx.stroke();

                            // Middle Layer Chevron
                            ctx.beginPath();
                            ctx.moveTo(2.5, 9.0);
                            ctx.lineTo(9, 12.0);
                            ctx.lineTo(15.5, 9.0);
                            ctx.stroke();

                            // Bottom Layer Chevron
                            ctx.beginPath();
                            ctx.moveTo(2.5, 12.5);
                            ctx.lineTo(9, 15.5);
                            ctx.lineTo(15.5, 12.5);
                            ctx.stroke();
                        }
                    }

                    Text {
                        text: "BC-250 OBERON APU"
                        color: "#ffffff"
                        font.family: "Plus Jakarta Sans"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    color: "#132b26"
                    border.color: "#21594e"
                    border.width: 1
                    radius: 6
                    implicitWidth: badgeText.implicitWidth + 14
                    implicitHeight: 22

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.dynamicKernelBadge
                        color: "#00f0a8"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff"; opacity: 0.08 }

            // CPU Zen 2 Card with Dynamic Oscilloscope Wave tracking CPU LOAD
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 70
                color: "#05090f"
                radius: 10
                border.color: "#152a38"
                border.width: 1
                clip: true

                // Left Blue Accent Strip: Inset Rounded Pill
                Rectangle {
                    width: 3
                    radius: 2
                    color: "#38bdf8"
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.leftMargin: 12
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "CPU Zen 2 (8c / 16t)"
                            color: "#e2e8f0"
                            font.family: "Plus Jakarta Sans"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "<font color='#38bdf8'><b>" + root.smoothCpuDieTemp.toFixed(1) + "\u00B0C</b></font> \u00B7 <font color='#e2e8f0'><b>" + Math.round(root.smoothCpuUsagePct) + "% LOAD</b></font> \u00B7 " + Math.round(root.smoothCpuFreqMhz) + " MHz"
                            textFormat: Text.RichText
                            color: "#94a3b8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }
                    }

                    // Dynamic Spline Waveform - Live Real-Time CPU Load
                    Canvas {
                        id: cpuSparkCanvas
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        renderTarget: Canvas.Image

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var w = width;
                            var h = height;
                            if (w <= 0 || h <= 0) return;

                            var hist = root.cpuLoadHistory;
                            if (!hist || hist.length === 0) {
                                hist = [root.smoothCpuUsagePct, root.smoothCpuUsagePct];
                            }

                            // Compute points across width
                            var pts = [];
                            var n = hist.length;
                            for (var i = 0; i < n; i++) {
                                var x = (i / (n - 1)) * w;
                                var val = Math.max(0, Math.min(100, hist[i]));
                                // Scale: 0% load = h * 0.85, 100% load = h * 0.15
                                var y = h * 0.85 - (val / 100.0) * (h * 0.70);
                                pts.push({ x: x, y: y });
                            }

                            // Area Gradient Fill
                            var grad = ctx.createLinearGradient(0, 0, 0, h);
                            grad.addColorStop(0, "rgba(56, 189, 248, 0.40)");
                            grad.addColorStop(1, "rgba(56, 189, 248, 0.0)");

                            ctx.beginPath();
                            ctx.moveTo(pts[0].x, pts[0].y);
                            for (var j = 1; j < pts.length - 1; j++) {
                                var xc = (pts[j].x + pts[j + 1].x) / 2;
                                var yc = (pts[j].y + pts[j + 1].y) / 2;
                                ctx.quadraticCurveTo(pts[j].x, pts[j].y, xc, yc);
                            }
                            if (pts.length > 1) {
                                ctx.quadraticCurveTo(pts[pts.length - 2].x, pts[pts.length - 2].y, pts[pts.length - 1].x, pts[pts.length - 1].y);
                            }
                            ctx.lineTo(w, h);
                            ctx.lineTo(0, h);
                            ctx.closePath();
                            ctx.fillStyle = grad;
                            ctx.fill();

                            // Glowing Smooth Spline Curve Line
                            ctx.beginPath();
                            ctx.moveTo(pts[0].x, pts[0].y);
                            for (var k = 1; k < pts.length - 1; k++) {
                                var xc2 = (pts[k].x + pts[k + 1].x) / 2;
                                var yc2 = (pts[k].y + pts[k + 1].y) / 2;
                                ctx.quadraticCurveTo(pts[k].x, pts[k].y, xc2, yc2);
                            }
                            if (pts.length > 1) {
                                ctx.quadraticCurveTo(pts[pts.length - 2].x, pts[pts.length - 2].y, pts[pts.length - 1].x, pts[pts.length - 1].y);
                            }
                            ctx.strokeStyle = "#38bdf8";
                            ctx.lineWidth = 2.0;
                            ctx.stroke();
                        }

                        Connections {
                            target: root
                            function onCpuLoadHistoryChanged() { cpuSparkCanvas.requestPaint(); }
                            function onSmoothCpuUsagePctChanged() { cpuSparkCanvas.requestPaint(); }
                        }
                    }
                }
            }

            // GPU Oberon Card with Dynamic Oscilloscope Wave tracking GPU LOAD
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 70
                color: "#05090f"
                radius: 10
                border.color: "#122a22"
                border.width: 1
                clip: true

                // Left Green Accent Strip: Inset Rounded Pill
                Rectangle {
                    width: 3
                    radius: 2
                    color: "#00f0a8"
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.leftMargin: 12
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "GPU Oberon (" + root.gpuCuActive + " CUs)"
                            color: "#e2e8f0"
                            font.family: "Plus Jakarta Sans"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "<font color='#00f0a8'><b>" + root.smoothGpuDieTemp.toFixed(1) + "\u00B0C</b></font> \u00B7 <font color='#e2e8f0'><b>" + Math.round(root.smoothGpuBusyPct) + "% LOAD</b></font> \u00B7 " + Math.round(root.smoothGpuSclkMhz) + " MHz"
                            textFormat: Text.RichText
                            color: "#94a3b8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }
                    }

                    // Dynamic Spline Waveform - Live Real-Time GPU Load
                    Canvas {
                        id: gpuSparkCanvas
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        renderTarget: Canvas.Image

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var w = width;
                            var h = height;
                            if (w <= 0 || h <= 0) return;

                            var hist = root.gpuLoadHistory;
                            if (!hist || hist.length === 0) {
                                hist = [root.smoothGpuBusyPct, root.smoothGpuBusyPct];
                            }

                            // Compute points across width
                            var pts = [];
                            var n = hist.length;
                            for (var i = 0; i < n; i++) {
                                var x = (i / (n - 1)) * w;
                                var val = Math.max(0, Math.min(100, hist[i]));
                                // Scale: 0% load = h * 0.85, 100% load = h * 0.15
                                var y = h * 0.85 - (val / 100.0) * (h * 0.70);
                                pts.push({ x: x, y: y });
                            }

                            // Area Gradient Fill
                            var grad = ctx.createLinearGradient(0, 0, 0, h);
                            grad.addColorStop(0, "rgba(0, 240, 168, 0.40)");
                            grad.addColorStop(1, "rgba(0, 240, 168, 0.0)");

                            ctx.beginPath();
                            ctx.moveTo(pts[0].x, pts[0].y);
                            for (var j = 1; j < pts.length - 1; j++) {
                                var xc = (pts[j].x + pts[j + 1].x) / 2;
                                var yc = (pts[j].y + pts[j + 1].y) / 2;
                                ctx.quadraticCurveTo(pts[j].x, pts[j].y, xc, yc);
                            }
                            if (pts.length > 1) {
                                ctx.quadraticCurveTo(pts[pts.length - 2].x, pts[pts.length - 2].y, pts[pts.length - 1].x, pts[pts.length - 1].y);
                            }
                            ctx.lineTo(w, h);
                            ctx.lineTo(0, h);
                            ctx.closePath();
                            ctx.fillStyle = grad;
                            ctx.fill();

                            // Glowing Smooth Spline Curve Line
                            ctx.beginPath();
                            ctx.moveTo(pts[0].x, pts[0].y);
                            for (var k = 1; k < pts.length - 1; k++) {
                                var xc2 = (pts[k].x + pts[k + 1].x) / 2;
                                var yc2 = (pts[k].y + pts[k + 1].y) / 2;
                                ctx.quadraticCurveTo(pts[k].x, pts[k].y, xc2, yc2);
                            }
                            if (pts.length > 1) {
                                ctx.quadraticCurveTo(pts[pts.length - 2].x, pts[pts.length - 2].y, pts[pts.length - 1].x, pts[pts.length - 1].y);
                            }
                            ctx.strokeStyle = "#00f0a8";
                            ctx.lineWidth = 2.0;
                            ctx.stroke();
                        }

                        Connections {
                            target: root
                            function onGpuLoadHistoryChanged() { gpuSparkCanvas.requestPaint(); }
                            function onSmoothGpuBusyPctChanged() { gpuSparkCanvas.requestPaint(); }
                        }
                    }
                }
            }

            // GDDR6 Heatmap (8 Chips IC)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 88
                color: "#060a10"
                radius: 10
                border.color: "#182430"
                border.width: 1

                // Left Amber Accent Strip: Inset Rounded Pill
                Rectangle {
                    width: 3
                    radius: 2
                    color: "#f59e0b"
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    anchors.leftMargin: 12
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: root.isPortuguese ? "GDDR6 MEM\u00D3RIA (8 CHIPS IC)" : "GDDR6 MEMORY (8 CHIPS IC)"
                            color: "#94a3b8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "HOTSPOT: " + root.smoothVramHotspotTemp.toFixed(1) + "\u00B0C (CHIP #" + root.vramHotspotChip + ")"
                            color: "#f59e0b"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: 8
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 42
                                radius: 5
                                property int chipTemp: (root.memoryChips && root.memoryChips.length > index) ? root.memoryChips[index] : 50
                                property bool isHotspot: (index === root.vramHotspotChip)
                                color: isHotspot ? "#291907" : "#0d1622"
                                border.color: isHotspot ? "#f59e0b" : "#1c2938"
                                border.width: isHotspot ? 1.5 : 1

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 1
                                    Text {
                                        text: "#" + index
                                        color: "#64748b"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 8
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Text {
                                        text: chipTemp + "\u00B0"
                                        color: isHotspot ? "#f59e0b" : "#ffffff"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 10
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Power Stats Grid with Inset Rounded Accent Bars
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 8
                    color: "#0a121c"
                    border.color: "#192432"

                    Rectangle {
                        width: 3
                        radius: 2
                        color: "#38bdf8"
                        anchors.left: parent.left
                        anchors.leftMargin: 3
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: root.isPortuguese ? "CONSUMO TOTAL" : "TOTAL POWER"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8; Layout.alignment: Qt.AlignHCenter }
                        Text { text: Math.round(root.smoothTotalPowerW) + "W TDP"; color: "#ffffff"; font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 8
                    color: "#0a121c"
                    border.color: "#192432"

                    Rectangle {
                        width: 3
                        radius: 2
                        color: "#38bdf8"
                        anchors.left: parent.left
                        anchors.leftMargin: 3
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: root.isPortuguese ? "TENS\u00C3O RAIL 12V" : "12V RAIL VOLTAGE"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8; Layout.alignment: Qt.AlignHCenter }
                        Text { text: (typeof root.smoothVin12v === "number" ? root.smoothVin12v.toFixed(2) : "12.00") + " V"; color: "#38bdf8"; font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 8
                    color: "#0a121c"
                    border.color: "#192432"

                    Rectangle {
                        width: 3
                        radius: 2
                        color: "#f59e0b"
                        anchors.left: parent.left
                        anchors.leftMargin: 3
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: "VRM MOS TEMP"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8; Layout.alignment: Qt.AlignHCenter }
                        Text { text: root.smoothVrmTemp.toFixed(1) + "\u00B0C"; color: "#f59e0b"; font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    }
                }
            }

            // Web Dashboard Button (Pill Action matching Concept 3)
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 10
                color: btnMouse.containsMouse ? "#123b32" : "#0d2b24"
                border.color: btnMouse.containsMouse ? "#00f0a8" : "#246152"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "\u2197"
                        color: "#00f0a8"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Text {
                        text: root.isPortuguese ? "Abrir Cockpit Pro Web" : "Open Cockpit Pro Web"
                        color: "#00f0a8"
                        font.family: "Plus Jakarta Sans"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Qt.openUrlExternally("http://localhost:8090/")
                        root.expanded = false
                    }
                }
            }
        }
    }
}
