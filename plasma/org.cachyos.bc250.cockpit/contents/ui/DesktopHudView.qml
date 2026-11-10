import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: hudRoot
    anchors.fill: parent

    // Official base dimensions: compact 280 x 420 (ultra-slim width, preserved dial proportions, punchy legible typography)
    implicitWidth: 280
    implicitHeight: 420

    Layout.minimumWidth: 280
    Layout.minimumHeight: 420
    Layout.preferredWidth: 280
    Layout.preferredHeight: 420
    Layout.maximumWidth: 1200
    Layout.maximumHeight: 1400

    // Component for circular hero gauge - EXACT proportions and size preserved
    component CircularGauge: Item {
        id: gaugeItem
        property real value: 50
        property real displayValue: value
        property real minVal: 20
        property real maxVal: 90
        property color strokeColor: "#00f0a8"
        property string title: "APU"
        property string subinfo: ""
        property string centerSub: ""
        property bool isOverclock: false

        Behavior on strokeColor {
            ColorAnimation { duration: 320; easing.type: Easing.OutQuad }
        }

        Layout.fillWidth: true
        Layout.minimumWidth: 68
        Layout.preferredWidth: 88
        height: 92

        ColumnLayout {
            anchors.fill: parent
            spacing: 2

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 68
                height: 68

                // Canvas is 76x76 centered inside 68x68, giving 11px padding around radius 25 so glow never clips
                Canvas {
                    id: canvas
                    anchors.centerIn: parent
                    width: 76
                    height: 76
                    renderTarget: Canvas.Image

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var cx = width / 2;
                        var cy = height / 2;
                        var r = 25;

                        // Background Track
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, Math.PI * 2);
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.08)";
                        ctx.lineWidth = 3.5;
                        ctx.stroke();

                        // Value Arc Calculation
                        var frac = Math.min(1.0, Math.max(0.0, (gaugeItem.value - gaugeItem.minVal) / (gaugeItem.maxVal - gaugeItem.minVal)));
                        var start = -Math.PI / 2;
                        var end = start + frac * (Math.PI * 2);

                        // Pass 1: Radiant Soft Neon Bloom Glow (smooth circular glow identical in shape to nominal dials)
                        ctx.shadowColor = gaugeItem.strokeColor.toString();
                        ctx.shadowBlur = gaugeItem.isOverclock ? 6 : 5;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, start, end);
                        ctx.strokeStyle = gaugeItem.strokeColor.toString();
                        ctx.lineWidth = gaugeItem.isOverclock ? 4.0 : 3.5;
                        ctx.lineCap = "round";
                        ctx.stroke();

                        // Pass 2: Crisp Core Arc on top
                        ctx.shadowBlur = 0;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, start, end);
                        ctx.strokeStyle = gaugeItem.strokeColor.toString();
                        ctx.lineWidth = 3.5;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }

                    Connections {
                        target: gaugeItem
                        function onValueChanged() { canvas.requestPaint(); }
                        function onStrokeColorChanged() { canvas.requestPaint(); }
                        function onIsOverclockChanged() { canvas.requestPaint(); }
                    }
                }

                // Centered Numeric Label: Legible and beautifully proportioned
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 1
                        Text {
                            text: gaugeItem.displayValue.toFixed(1)
                            color: "#ffffff"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: "\u00B0C"
                            color: gaugeItem.isOverclock ? gaugeItem.strokeColor : "#fde047"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                            font.bold: true
                        }
                    }

                    Text {
                        text: gaugeItem.centerSub
                        color: gaugeItem.isOverclock ? gaugeItem.strokeColor : "#64748b"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 7
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Text {
                text: gaugeItem.title
                color: gaugeItem.strokeColor
                font.family: "JetBrains Mono"
                font.pixelSize: gaugeItem.isOverclock ? 7.5 : 8
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: gaugeItem.subinfo
                color: gaugeItem.isOverclock ? "#fca5a5" : "#94a3b8"
                font.family: "JetBrains Mono"
                font.pixelSize: 7
                font.bold: gaugeItem.isOverclock
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    Rectangle {
        id: hudBg
        anchors.fill: parent
        color: "#0a101a"
        radius: 16
        border.color: "#1c4036"
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 7
            spacing: 4

            // Header (Adaptive to width)
            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Rectangle {
                    width: 22
                    height: 22
                    radius: 5
                    color: "#11261f"
                    border.color: "#1e5244"
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "org.cachyos.bc250.cockpit"
                        implicitWidth: 13
                        implicitHeight: 13
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Text {
                        text: "BC-250 OBERON APU"
                        color: "#ffffff"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    Text {
                        text: root.dynamicKernelBadge
                        color: "#00f0a8"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 7
                        elide: Text.ElideRight
                    }
                }

                Item { Layout.fillWidth: true }

                // Fully rounded oval pill badge with generous padding around the glowing dot
                Rectangle {
                    color: (root.isCpuOverclock || root.isGpuOverclock) ? "#2b100c" : "#11261f"
                    border.color: (root.isCpuOverclock || root.isGpuOverclock) ? "#6e2316" : "#1e5244"
                    border.width: 1
                    radius: 10
                    implicitWidth: (root.isCpuOverclock || root.isGpuOverclock) ? 88 : 80
                    implicitHeight: 20
                    Behavior on color { ColorAnimation { duration: 320 } }
                    Behavior on border.color { ColorAnimation { duration: 320 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2
                            color: (root.isCpuOverclock || root.isGpuOverclock) ? "#ff4500" : "#00f0a8"
                            Layout.alignment: Qt.AlignVCenter
                            Behavior on color { ColorAnimation { duration: 320 } }
                        }
                        Text {
                            text: (root.isCpuOverclock || root.isGpuOverclock) ? "OC ACTIVE" : (root.gpuCuActive + " CUs ONLINE")
                            color: (root.isCpuOverclock || root.isGpuOverclock) ? "#ffedd5" : "#00f0a8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                            font.bold: true
                            Layout.alignment: Qt.AlignVCenter
                            Behavior on color { ColorAnimation { duration: 320 } }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff"; opacity: 0.08 }

            // 3 Circular Hero Gauges: CPU DIE, GPU DIE, VRAM HOTSPOT with subtle dividing bars
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                CircularGauge {
                    value: root.smoothCpuDieTemp
                    displayValue: root.smoothCpuDieTemp
                    isOverclock: root.isCpuOverclock
                    strokeColor: root.isCpuOverclock ? "#ff4500" : "#38bdf8"
                    centerSub: root.isCpuOverclock ? "BOOST" : "CPU DIE"
                    title: root.isCpuOverclock ? "CPU OVERCLOCK" : "CPU ZEN 2"
                    subinfo: root.isCpuOverclock ? (Math.round(root.smoothCpuFreqMhz) + " MHz BOOST") : (root.cpuCores + "c / " + root.cpuThreads + "t \u00B7 " + root.cpuMaxTempC + "\u00B0C")
                }

                Rectangle {
                    width: 1
                    height: 52
                    color: "#ffffff"
                    opacity: 0.08
                    Layout.alignment: Qt.AlignVCenter
                }

                CircularGauge {
                    value: root.smoothGpuDieTemp
                    displayValue: root.smoothGpuDieTemp
                    isOverclock: root.isGpuOverclock
                    strokeColor: root.isGpuOverclock ? "#ff3300" : "#00f0a8"
                    centerSub: root.isGpuOverclock ? "BOOST" : "GPU DIE"
                    title: root.isGpuOverclock ? "GPU OVERCLOCK" : "GPU RDNA2"
                    subinfo: root.isGpuOverclock ? (Math.round(root.smoothGpuSclkMhz) + " MHz BOOST") : (root.gpuCuActive + " CUs \u00B7 " + root.gpuShaders + " SH")
                }

                Rectangle {
                    width: 1
                    height: 52
                    color: "#ffffff"
                    opacity: 0.08
                    Layout.alignment: Qt.AlignVCenter
                }

                CircularGauge {
                    value: root.smoothVramHotspotTemp
                    displayValue: root.smoothVramHotspotTemp
                    strokeColor: "#f59e0b"
                    centerSub: "HOTSPOT"
                    title: "VRAM HOTSPOT"
                    subinfo: "Chip #" + root.vramHotspotChip + " \u00B7 " + root.memoryTotalGb + "GB"
                }
            }

            // Separator bar below the 3 hero dials (matching the top bar)
            Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff"; opacity: 0.08 }

            // Processing Cards: CPU & GPU with Live Frequency Waveforms (Sparklines)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // CPU Card with Live Sparkline
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 45
                    color: "#060a12"
                    radius: 6
                    border.color: root.isCpuOverclock ? "#6b1e16" : "#15202c"
                    Behavior on border.color { ColorAnimation { duration: 320 } }

                    Rectangle {
                        width: 3
                        color: root.isCpuOverclock ? "#ff4500" : "#38bdf8"
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 3
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        Behavior on color { ColorAnimation { duration: 320 } }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        anchors.leftMargin: 10
                        anchors.rightMargin: 5
                        spacing: 2

                        // Header Row: Name & Clock (Restored prominent bold legibility)
                        RowLayout {
                            Layout.fillWidth: true
                            RowLayout {
                                spacing: 4
                                Kirigami.Icon {
                                    source: "cpu"
                                    implicitWidth: 12
                                    implicitHeight: 12
                                    color: root.isCpuOverclock ? "#ff4500" : "#38bdf8"
                                    Behavior on color { ColorAnimation { duration: 320 } }
                                }
                                Text {
                                    text: root.isCpuOverclock ? "CPU Zen 2 (Overclock)" : (root.isPortuguese ? "Frequ\u00EAncia CPU Zen 2" : "CPU Zen 2 Frequency")
                                    color: root.isCpuOverclock ? "#ffedd5" : "#e2e8f0"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
                                    font.bold: true
                                    Behavior on color { ColorAnimation { duration: 320 } }
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "<font color='" + (root.isCpuOverclock ? "#ff4500" : "#ffffff") + "'><b>" + Math.round(root.smoothCpuFreqMhz) + "</b></font> <font color='#64748b' size='-1'>/ " + root.cpuTargetFreqMhz + " MHz</font>"
                                textFormat: Text.RichText
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        // Sparkline Waveform & Load Badge
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Canvas {
                                id: cpuSparkCanvas
                                Layout.fillWidth: true
                                height: 14
                                renderTarget: Canvas.Image

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    var w = width;
                                    var h = height;
                                    var hist = root.cpuFreqHistory;
                                    if (!hist || hist.length < 2) return;

                                    var minVal = 400;
                                    var maxVal = root.cpuTargetFreqMhz || 3500;
                                    var step = w / (hist.length - 1);

                                    ctx.beginPath();
                                    var y0 = h - Math.min(h - 2, Math.max(2, ((hist[0] - minVal) / (maxVal - minVal)) * (h - 4) + 2));
                                    ctx.moveTo(0, y0);
                                    for (var i = 1; i < hist.length; i++) {
                                        var xi = i * step;
                                        var yi = h - Math.min(h - 2, Math.max(2, ((hist[i] - minVal) / (maxVal - minVal)) * (h - 4) + 2));
                                        var prevXi = (i - 1) * step;
                                        var prevYi = h - Math.min(h - 2, Math.max(2, ((hist[i - 1] - minVal) / (maxVal - minVal)) * (h - 4) + 2));
                                        ctx.bezierCurveTo((prevXi + xi) / 2, prevYi, (prevXi + xi) / 2, yi, xi, yi);
                                    }
                                    ctx.lineTo(w, h);
                                    ctx.lineTo(0, h);
                                    ctx.closePath();
                                    ctx.fillStyle = root.isCpuOverclock ? "rgba(255, 69, 0, 0.22)" : "rgba(56, 189, 248, 0.16)";
                                    ctx.fill();

                                    ctx.beginPath();
                                    ctx.moveTo(0, y0);
                                    for (var j = 1; j < hist.length; j++) {
                                        var xj = j * step;
                                        var yj = h - Math.min(h - 2, Math.max(2, ((hist[j] - minVal) / (maxVal - minVal)) * (h - 4) + 2));
                                        var prevXj = (j - 1) * step;
                                        var prevYj = h - Math.min(h - 2, Math.max(2, ((hist[j - 1] - minVal) / (maxVal - minVal)) * (h - 4) + 2));
                                        ctx.bezierCurveTo((prevXj + xj) / 2, prevYj, (prevXj + xj) / 2, yj, xj, yj);
                                    }
                                    ctx.strokeStyle = root.isCpuOverclock ? "#ff4500" : "#38bdf8";
                                    ctx.lineWidth = 1.4;
                                    ctx.stroke();
                                }

                                Connections {
                                    target: root
                                    function onCpuFreqHistoryChanged() { cpuSparkCanvas.requestPaint(); }
                                    function onIsCpuOverclockChanged() { cpuSparkCanvas.requestPaint(); }
                                }
                            }

                            Rectangle {
                                implicitWidth: 54
                                height: 17
                                radius: 3
                                color: root.isCpuOverclock ? "#2d120a" : "#102330"
                                border.color: root.isCpuOverclock ? "#5a2214" : "#1c3c4f"
                                Behavior on color { ColorAnimation { duration: 320 } }
                                Behavior on border.color { ColorAnimation { duration: 320 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: root.smoothCpuUsagePct.toFixed(0) + (root.isPortuguese ? "% CARGA" : "% LOAD")
                                    color: root.isCpuOverclock ? "#ff7849" : "#38bdf8"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 8
                                    font.bold: true
                                    Behavior on color { ColorAnimation { duration: 320 } }
                                }
                            }
                        }
                    }
                }

                // GPU Card with Live Sparkline
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 45
                    color: "#060a12"
                    radius: 6
                    border.color: root.isGpuOverclock ? "#6b1410" : "#122a22"
                    Behavior on border.color { ColorAnimation { duration: 320 } }

                    Rectangle {
                        width: 3
                        color: root.isGpuOverclock ? "#ff3300" : "#00f0a8"
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 3
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        Behavior on color { ColorAnimation { duration: 320 } }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        anchors.leftMargin: 10
                        anchors.rightMargin: 5
                        spacing: 2

                        // Header Row: Name & Clock (Restored prominent bold legibility)
                        RowLayout {
                            Layout.fillWidth: true
                            RowLayout {
                                spacing: 4
                                Kirigami.Icon {
                                    source: "video-card"
                                    implicitWidth: 12
                                    implicitHeight: 12
                                    color: root.isGpuOverclock ? "#ff3300" : "#00f0a8"
                                    Behavior on color { ColorAnimation { duration: 320 } }
                                }
                                Text {
                                    text: root.isGpuOverclock ? "GPU Oberon (Overclock)" : (root.isPortuguese ? "Frequ\u00EAncia GPU Oberon" : "GPU Oberon Frequency")
                                    color: root.isGpuOverclock ? "#fff1f2" : "#e2e8f0"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
                                    font.bold: true
                                    Behavior on color { ColorAnimation { duration: 320 } }
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "<font color='" + (root.isGpuOverclock ? "#ff3300" : "#ffffff") + "'><b>" + Math.round(root.smoothGpuSclkMhz) + "</b></font> <font color='#64748b' size='-1'>/ " + root.gpuMaxFreqMhz + " MHz</font>"
                                textFormat: Text.RichText
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        // Sparkline Waveform & Load Badge
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Canvas {
                                id: gpuSparkCanvas
                                Layout.fillWidth: true
                                height: 14
                                renderTarget: Canvas.Image

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    var w = width;
                                    var h = height;
                                    var hist = root.gpuFreqHistory;
                                    if (!hist || hist.length < 2) return;

                                    var minVal = 300;
                                    var maxVal = root.gpuMaxFreqMhz || 1850;
                                    var step = w / (hist.length - 1);

                                    ctx.beginPath();
                                    var y0 = h - Math.min(h - 2, Math.max(2, ((hist[0] - minVal) / (maxVal - minVal)) * (h - 4) + 2));
                                    ctx.moveTo(0, y0);
                                    for (var i = 1; i < hist.length; i++) {
                                        var xi = i * step;
                                        var yi = h - Math.min(h - 2, Math.max(2, ((hist[i] - minVal) / (maxVal - minVal)) * (h - 4) + 2));
                                        var prevXi = (i - 1) * step;
                                        var prevYi = h - Math.min(h - 2, Math.max(2, ((hist[i - 1] - minVal) / (maxVal - minVal)) * (h - 4) + 2));
                                        ctx.bezierCurveTo((prevXi + xi) / 2, prevYi, (prevXi + xi) / 2, yi, xi, yi);
                                    }
                                    ctx.lineTo(w, h);
                                    ctx.lineTo(0, h);
                                    ctx.closePath();
                                    ctx.fillStyle = root.isGpuOverclock ? "rgba(255, 51, 0, 0.22)" : "rgba(0, 240, 168, 0.16)";
                                    ctx.fill();

                                    ctx.beginPath();
                                    ctx.moveTo(0, y0);
                                    for (var j = 1; j < hist.length; j++) {
                                        var xj = j * step;
                                        var yj = h - Math.min(h - 2, Math.max(2, ((hist[j] - minVal) / (maxVal - minVal)) * (h - 4) + 2));
                                        var prevXj = (j - 1) * step;
                                        var prevYj = h - Math.min(h - 2, Math.max(2, ((hist[j - 1] - minVal) / (maxVal - minVal)) * (h - 4) + 2));
                                        ctx.bezierCurveTo((prevXj + xj) / 2, prevYj, (prevXj + xj) / 2, yj, xj, yj);
                                    }
                                    ctx.strokeStyle = root.isGpuOverclock ? "#ff3300" : "#00f0a8";
                                    ctx.lineWidth = 1.4;
                                    ctx.stroke();
                                }

                                Connections {
                                    target: root
                                    function onGpuFreqHistoryChanged() { gpuSparkCanvas.requestPaint(); }
                                    function onIsGpuOverclockChanged() { gpuSparkCanvas.requestPaint(); }
                                }
                            }

                            Rectangle {
                                implicitWidth: 54
                                height: 17
                                radius: 3
                                color: root.isGpuOverclock ? "#2d0e08" : "#0e261f"
                                border.color: root.isGpuOverclock ? "#5c1d12" : "#1c4a3b"
                                Behavior on color { ColorAnimation { duration: 320 } }
                                Behavior on border.color { ColorAnimation { duration: 320 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: root.smoothGpuBusyPct.toFixed(0) + (root.isPortuguese ? "% CARGA" : "% LOAD")
                                    color: root.isGpuOverclock ? "#ff6b4a" : "#34d399"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 8
                                    font.bold: true
                                    Behavior on color { ColorAnimation { duration: 320 } }
                                }
                            }
                        }
                    }
                }
            }

            // Visual breathing room before VRM Telemetry
            Item {
                Layout.fillWidth: true
                height: 3
            }

            // Section Header: ALIMENTAÇÃO & TELEMETRIA VRM (Bilingual, Restored Bold Size)
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.isPortuguese ? "ALIMENTA\u00C7\u00C3O & TELEMETRIA VRM" : "POWER DELIVERY & VRM TELEMETRY"
                    color: "#94a3b8"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: (root.isPortuguese ? "RAIL 12V: " : "12V RAIL: ") + "<font color='#fde047'><b>" + root.smoothVin12v.toFixed(2) + "V</b></font>"
                    textFormat: Text.RichText
                    color: "#64748b"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                }
            }

            // 2 Distinct Telemetry Cards: CPU VRM (Left) & GPU VRM (Right)
            // Highly legible 9px bold numbers and clean 8px labels
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                // CPU VRM Card (Left)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 118
                    radius: 7
                    color: "#081420"
                    border.color: "#163447"

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
                        anchors.margins: 5
                        anchors.leftMargin: 10
                        spacing: 2

                        // Card Header
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "\u25CF CPU VRM"
                                color: "#38bdf8"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.smoothCpuVrmTemp.toFixed(1) + "\u00B0C"
                                color: "#38bdf8"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff"; opacity: 0.08 }

                        // Row 1: VCore
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "VCore"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.smoothCpuVout.toFixed(3) + " V"; color: "#ffffff"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                        }

                        // Row 2: Corrente / Current
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: root.isPortuguese ? "Corrente" : "Current"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.smoothCpuIout.toFixed(1) + " A"; color: "#ffffff"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                        }

                        // Row 3: Potência VRM / Active Power
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: root.isPortuguese ? "Pot\u00EAncia" : "Power"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.smoothCpuPout.toFixed(1) + " W"; color: "#38bdf8"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                        }

                        // Row 4: Tensão Entrada 12V / Supply Rail
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: root.isPortuguese ? "Entrada Vin" : "Input Vin"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.smoothCpuVin.toFixed(2) + " V"; color: "#fde047"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                        }

                        // Row 5: Temperatura DrMOS / MOSFET Temp
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: root.isPortuguese ? "Temp MOSFET" : "MOSFET Temp"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.smoothCpuVrmTemp.toFixed(1) + " \u00B0C"; color: "#cbd5e1"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                        }
                    }
                }

                // GPU VRM Card (Right)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 118
                    radius: 7
                    color: "#071813"
                    border.color: "#13382c"

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
                        anchors.margins: 5
                        anchors.leftMargin: 10
                        spacing: 2

                        // Card Header
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "\u25CF GPU VRM"
                                color: "#00f0a8"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.smoothGpuVrmTemp.toFixed(1) + "\u00B0C"
                                color: "#00f0a8"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff"; opacity: 0.08 }

                        // Row 1: VDDCR
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "VDDCR"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.smoothGpuVout.toFixed(3) + " V"; color: "#ffffff"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                        }

                        // Row 2: Corrente / Current
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: root.isPortuguese ? "Corrente" : "Current"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.smoothGpuIout.toFixed(1) + " A"; color: "#ffffff"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                        }

                        // Row 3: Potência VRM / Active Power
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: root.isPortuguese ? "Pot\u00EAncia" : "Power"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.smoothGpuPout.toFixed(1) + " W"; color: "#00f0a8"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                        }

                        // Row 4: Tensão Entrada 12V / Supply Rail
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: root.isPortuguese ? "Entrada Vin" : "Input Vin"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.smoothGpuVin.toFixed(2) + " V"; color: "#fde047"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                        }

                        // Row 5: Temperatura DrMOS / MOSFET Temp
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: root.isPortuguese ? "Temp MOSFET" : "MOSFET Temp"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.smoothGpuVrmTemp.toFixed(1) + " \u00B0C"; color: "#cbd5e1"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                        }
                    }
                }
            }

            // Spacer absorbs remaining space and anchors footer to the bottom with ample clearance
            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 2
            }

            // Footer: REAL SMU PPT POWER, VRM TEMP, FAN (left side) and TELEMETRY: COCKPIT PRO (far right)
            Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff"; opacity: 0.08 }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                // Left items group (Prominent bold legibility)
                RowLayout {
                    spacing: 12

                    ColumnLayout {
                        spacing: 1
                        Text {
                            text: root.isPortuguese ? "POT\u00CANCIA" : "POWER"
                            color: "#64748b"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: Math.round(root.smoothTotalPowerW) + "W SMU"
                            color: "#f1f5f9"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    ColumnLayout {
                        spacing: 1
                        Text { text: "VRM TEMP"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 7 }
                        Text { text: root.smoothVrmTemp.toFixed(1) + "\u00B0C"; color: "#38bdf8"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                    }

                    ColumnLayout {
                        spacing: 1
                        Text { text: "COOLING FAN"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 7 }
                        Text { text: Math.round(root.smoothFanRpm) + " RPM"; color: "#f1f5f9"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                    }
                }

                // Spacer pushes Telemetry all the way to the right
                Item { Layout.fillWidth: true }

                // Right corner: TELEMETRY horizontally centered directly above COCKPIT PRO
                ColumnLayout {
                    spacing: 1
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Text {
                        text: "TELEMETRY"
                        color: "#64748b"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 7
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "COCKPIT PRO"
                        color: "#00f0a8"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
