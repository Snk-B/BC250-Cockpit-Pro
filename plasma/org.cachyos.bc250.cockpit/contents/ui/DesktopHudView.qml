import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: hudRoot
    implicitWidth: 480
    implicitHeight: 640

    // Component for circular gauge
    component CircularGauge: Item {
        id: gaugeItem
        property real value: 50
        property real minVal: 20
        property real maxVal: 90
        property color strokeColor: "#00f0a8"
        property string title: "APU"
        property string subinfo: ""
        property string centerSub: ""

        width: 120
        height: 145

        ColumnLayout {
            anchors.fill: parent
            spacing: 4

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 104
                height: 104

                Canvas {
                    id: canvas
                    anchors.fill: parent
                    renderTarget: Canvas.Image

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var cx = width / 2;
                        var cy = height / 2;
                        var r = width / 2 - 8;

                        // Background Track
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, Math.PI * 2);
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.08)";
                        ctx.lineWidth = 7;
                        ctx.stroke();

                        // Value Arc
                        var frac = Math.min(1.0, Math.max(0.0, (gaugeItem.value - gaugeItem.minVal) / (gaugeItem.maxVal - gaugeItem.minVal)));
                        var start = -Math.PI / 2;
                        var end = start + frac * (Math.PI * 2);

                        ctx.beginPath();
                        ctx.arc(cx, cy, r, start, end);
                        ctx.strokeStyle = gaugeItem.strokeColor.toString();
                        ctx.lineWidth = 7;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }

                    Connections {
                        target: gaugeItem
                        function onValueChanged() { canvas.requestPaint(); }
                    }
                }

                // Centered Label
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 1
                        Text {
                            text: gaugeItem.value.toFixed(1)
                            color: "#ffffff"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 20
                            font.bold: true
                        }
                        Text {
                            text: "°C"
                            color: "#fde047"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Text {
                        text: gaugeItem.centerSub
                        color: "#64748b"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 8
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Text {
                text: gaugeItem.title
                color: gaugeItem.strokeColor
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: gaugeItem.subinfo
                color: "#64748b"
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a101a"
        radius: 20
        border.color: "#1c4036"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // Header
            RowLayout {
                Layout.fillWidth: true

                RowLayout {
                    spacing: 10
                    Rectangle {
                        width: 34
                        height: 34
                        radius: 8
                        color: "#11261f"
                        border.color: "#1e5244"
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            source: "cpu"
                            implicitWidth: 18
                            implicitHeight: 18
                            color: "#00f0a8"
                        }
                    }

                    ColumnLayout {
                        spacing: 1
                        Text {
                            text: "BC-250 OBERON APU"
                            color: "#ffffff"
                            font.family: "Plus Jakarta Sans"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            text: "CACHYOS BORE · KERNEL " + root.kernelRelease
                            color: "#00f0a8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    color: "#11261f"
                    border.color: "#1e5244"
                    radius: 12
                    implicitWidth: 96
                    implicitHeight: 24

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Rectangle { width: 5; height: 5; radius: 3; color: "#00f0a8" }
                        Text {
                            text: "40 CUs ONLINE"
                            color: "#00f0a8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff"; opacity: 0.08 }

            // 3 Circular Hero Gauges: CPU DIE, GPU DIE, VRAM HOTSPOT
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                CircularGauge {
                    Layout.fillWidth: true
                    value: root.cpuDieTemp
                    strokeColor: "#38bdf8"
                    centerSub: "CPU DIE"
                    title: "CPU ZEN 2"
                    subinfo: "8c / 16t · Teto 80°C"
                }

                CircularGauge {
                    Layout.fillWidth: true
                    value: root.gpuDieTemp
                    strokeColor: "#00f0a8"
                    centerSub: "GPU DIE"
                    title: "GPU RDNA2"
                    subinfo: "40 CUs · 2560 Shaders"
                }

                CircularGauge {
                    Layout.fillWidth: true
                    value: root.vramHotspotTemp
                    strokeColor: "#f59e0b"
                    centerSub: "HOTSPOT"
                    title: "VRAM HOTSPOT"
                    subinfo: "Chip #" + root.vramHotspotChip + " · 16GB GDDR6"
                }
            }

            // Separated Processing Cards: CPU and GPU
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                // CPU Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    color: "#05090f"
                    radius: 10
                    border.color: "#152a38"

                    Rectangle {
                        width: 3
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        color: "#38bdf8"
                        radius: 2
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        anchors.leftMargin: 14
                        spacing: 8

                        Text { text: "CPU Zen 2 Frequency"; color: "#cbd5e1"; font.family: "Plus Jakarta Sans"; font.pixelSize: 11; font.bold: true }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "<font color='#ffffff'><b>" + root.cpuFreqMhz + "</b></font> <font color='#64748b' size='-2'>/ " + root.cpuTargetFreqMhz + " MHz</font>"
                            textFormat: Text.RichText
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                        }

                        Rectangle {
                            implicitWidth: 70
                            height: 22
                            radius: 5
                            color: "#102330"
                            border.color: "#1c3c4f"
                            Text {
                                anchors.centerIn: parent
                                text: root.cpuUsagePct.toFixed(0) + "% CARGA"
                                color: "#38bdf8"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }
                }

                // GPU Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    color: "#05090f"
                    radius: 10
                    border.color: "#122a22"

                    Rectangle {
                        width: 3
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        color: "#00f0a8"
                        radius: 2
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        anchors.leftMargin: 14
                        spacing: 8

                        Text { text: "GPU Oberon Frequency"; color: "#cbd5e1"; font.family: "Plus Jakarta Sans"; font.pixelSize: 11; font.bold: true }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "<font color='#ffffff'><b>" + root.gpuSclkMhz + "</b></font> <font color='#64748b' size='-2'>/ " + root.gpuMaxFreqMhz + " MHz</font>"
                            textFormat: Text.RichText
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                        }

                        Rectangle {
                            implicitWidth: 70
                            height: 22
                            radius: 5
                            color: "#0e261f"
                            border.color: "#1c4a3b"
                            Text {
                                anchors.centerIn: parent
                                text: root.gpuBusyPct.toFixed(0) + "% CARGA"
                                color: "#34d399"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }
                }
            }

            // Silicon Matrix (4 SEs / 20 WGPs / 40 CUs)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 66
                color: "#06090e"
                radius: 10
                border.color: "#15202c"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "MATRIZ DE SILÍCIO (4 SHADER ENGINES)"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: "20/20 WGP · FULL DIE"; color: "#00f0a8"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: ["SE0", "SE1", "SE2", "SE3"]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 5
                                color: "#0b121a"
                                border.color: "#182635"

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Text { text: modelData; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 7; Layout.alignment: Qt.AlignHCenter }
                                    RowLayout {
                                        spacing: 2
                                        Repeater {
                                            model: 5
                                            delegate: Rectangle {
                                                width: 5
                                                height: 5
                                                radius: 2
                                                color: "#00f0a8"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Footer: POTÊNCIA, VRM TEMP, FAN, TELEMETRY: COCKPIT PRO
            Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff"; opacity: 0.08 }

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 1
                    Text { text: "POTÊNCIA"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                    Text { text: root.totalPowerW.toFixed(0) + "W TDP"; color: "#ffffff"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    spacing: 1
                    Text { text: "VRM TEMP"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                    Text { text: root.vrmTemp.toFixed(1) + "°C"; color: "#38bdf8"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    spacing: 1
                    Text { text: "COOLING FAN"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                    Text { text: root.fanRpm + " RPM"; color: "#ffffff"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    spacing: 1
                    Text { text: "TELEMETRY"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8; Layout.alignment: Qt.AlignRight }
                    Text { text: "COCKPIT PRO"; color: "#00f0a8"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; Layout.alignment: Qt.AlignRight }
                }
            }
        }
    }
}
