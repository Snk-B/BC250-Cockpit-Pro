import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: dockRoot
    implicitWidth: 500
    implicitHeight: 76
    width: 500
    height: 76

    Layout.minimumWidth: 460
    Layout.preferredWidth: 500
    Layout.maximumWidth: 540

    Layout.minimumHeight: 76
    Layout.preferredHeight: 76
    Layout.maximumHeight: 76

    Rectangle {
        id: dockBg
        width: Math.min(Math.max(parent.width, 480), 512)
        height: 76
        anchors.centerIn: parent
        color: "#090e17"
        radius: 14
        border.color: "#163640"
        border.width: 1
        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 7
            anchors.rightMargin: 7
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            spacing: 6

            // -------------------------------------------------------------
            // Brand Identity Module (OBERON APU · 40 CUs)
            // -------------------------------------------------------------
            ColumnLayout {
                Layout.preferredWidth: 78
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                spacing: 3

                Item { Layout.fillHeight: true }

                Rectangle {
                    width: 20
                    height: 20
                    radius: 4
                    color: "#0a1e1b"
                    border.color: "#1c5549"
                    border.width: 1
                    Layout.alignment: Qt.AlignHCenter

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "org.cachyos.bc250.cockpit"
                        implicitWidth: 13
                        implicitHeight: 13
                    }
                }

                Text {
                    text: "OBERON APU"
                    color: "#ffffff"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    implicitWidth: 42
                    implicitHeight: 13
                    radius: 3
                    color: "#0a241e"
                    border.color: "#1c5549"
                    border.width: 1
                    Layout.alignment: Qt.AlignHCenter

                    Text {
                        anchors.centerIn: parent
                        text: root.gpuCuActive + " CUs"
                        color: "#00f0a8"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 6
                        font.bold: true
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // Subtle vertical separator
            Rectangle {
                width: 1
                Layout.fillHeight: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                color: "#ffffff"
                opacity: 0.08
            }

            // -------------------------------------------------------------
            // 4 Telemetry Tiles Grid (Pílulas Arredondadas + Números Brancos)
            // -------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 5

                // Tile 1: CPU ZEN 2 DIE
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#060b13"
                    radius: 7
                    border.color: "#163447"
                    border.width: 1

                    // Left Cyan Neon Accent: Pílula arredondada interna que orna perfeitamente com a borda
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
                        anchors.leftMargin: 10
                        anchors.rightMargin: 5
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        spacing: 1

                        Text {
                            text: "CPU ZEN 2 DIE"
                            color: "#38bdf8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                            font.bold: true
                        }
                        Text {
                            text: "<font color='#ffffff'><b>" + root.smoothCpuDieTemp.toFixed(1) + "</b></font><font color='#fde047'>\u00B0C</font>"
                            textFormat: Text.RichText
                            font.family: "JetBrains Mono"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            text: root.isPortuguese ? (root.cpuCores + "c/" + root.cpuThreads + "t \u00B7 " + root.smoothCpuUsagePct.toFixed(0) + "% Carga") : (root.cpuCores + "c/" + root.cpuThreads + "t \u00B7 " + root.smoothCpuUsagePct.toFixed(0) + "% Load")
                            color: "#94a3b8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                        }
                    }
                }

                // Tile 2: GPU RDNA2 DIE
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#060b13"
                    radius: 7
                    border.color: "#102f23"
                    border.width: 1

                    // Left Emerald Neon Accent: Pílula arredondada interna
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
                        anchors.leftMargin: 10
                        anchors.rightMargin: 5
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        spacing: 1

                        Text {
                            text: "GPU RDNA2 DIE"
                            color: "#00f0a8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                            font.bold: true
                        }
                        Text {
                            text: "<font color='#ffffff'><b>" + root.smoothGpuDieTemp.toFixed(1) + "</b></font><font color='#fde047'>\u00B0C</font>"
                            textFormat: Text.RichText
                            font.family: "JetBrains Mono"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            text: root.isPortuguese ? (root.gpuCuActive + " CUs \u00B7 " + root.smoothGpuBusyPct.toFixed(0) + "% Carga") : (root.gpuCuActive + " CUs \u00B7 " + root.smoothGpuBusyPct.toFixed(0) + "% Load")
                            color: "#94a3b8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                        }
                    }
                }

                // Tile 3: VRM HOTSPOT
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#060b13"
                    radius: 7
                    border.color: "#382512"
                    border.width: 1

                    // Left Amber Neon Accent: Pílula arredondada interna
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
                        anchors.leftMargin: 10
                        anchors.rightMargin: 5
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        spacing: 1

                        Text {
                            text: "VRM HOTSPOT"
                            color: "#f59e0b"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                            font.bold: true
                        }
                        Text {
                            text: "<font color='#ffffff'><b>" + root.smoothVramHotspotTemp.toFixed(1) + "</b></font><font color='#fde047'>\u00B0C</font>"
                            textFormat: Text.RichText
                            font.family: "JetBrains Mono"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            text: "DrMOS \u00B7 " + Math.round(root.smoothTotalPowerW) + "W SMU"
                            color: "#94a3b8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                        }
                    }
                }

                // Tile 4: Active Clocks with Tags & Dual Ratios
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#060b13"
                    radius: 7
                    border.color: "#182430"
                    border.width: 1

                    // Left Slate Accent: Pílula arredondada interna
                    Rectangle {
                        width: 3
                        radius: 2
                        color: "#64748b"
                        anchors.left: parent.left
                        anchors.leftMargin: 3
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 5
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        spacing: 2

                        Text {
                            text: root.isPortuguese ? "FREQU\u00CANCIAS ATIVAS" : "ACTIVE CLOCKS"
                            color: "#94a3b8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Rectangle {
                                width: 20
                                height: 11
                                radius: 2.5
                                color: "#122a38"
                                border.color: "#20465c"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "CPU"
                                    color: "#38bdf8"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 6
                                    font.bold: true
                                }
                            }

                            Text {
                                text: "<font color='#ffffff'><b>" + Math.round(root.smoothCpuFreqMhz) + "</b></font> <font color='#64748b' size='-2'>/ " + root.cpuTargetFreqMhz + "</font>"
                                textFormat: Text.RichText
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Rectangle {
                                width: 20
                                height: 11
                                radius: 2.5
                                color: "#0d261e"
                                border.color: "#194d3d"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "GPU"
                                    color: "#00f0a8"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 6
                                    font.bold: true
                                }
                            }

                            Text {
                                text: "<font color='#ffffff'><b>" + Math.round(root.smoothGpuSclkMhz) + "</b></font> <font color='#64748b' size='-2'>/ " + root.gpuMaxFreqMhz + "</font>"
                                textFormat: Text.RichText
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8
                            }
                        }
                    }
                }
            }
        }
    }
}
