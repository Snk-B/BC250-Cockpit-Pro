import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: flyoutRoot
    implicitWidth: 410
    implicitHeight: 490

    Rectangle {
        anchors.fill: parent
        color: "#0a101a"
        radius: 16
        border.color: "#1c3d36"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true

                RowLayout {
                    spacing: 8
                    Kirigami.Icon {
                        source: "sensors-temperature-symbolic"
                        implicitWidth: 18
                        implicitHeight: 18
                        color: "#00f0a8"
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
                        text: "CACHYOS BORE"
                        color: "#00f0a8"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff"; opacity: 0.08 }

            // CPU Zen 2 Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                color: "#05090f"
                radius: 10
                border.color: "#152a38"
                border.width: 1

                Rectangle {
                    width: 3
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    color: "#38bdf8"
                    radius: 2
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    anchors.leftMargin: 14
                    spacing: 4

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
                            text: "<font color='#38bdf8'><b>" + root.cpuDieTemp.toFixed(1) + "°C</b></font> · " + root.cpuFreqMhz + " / " + root.cpuTargetFreqMhz + " MHz"
                            textFormat: Text.RichText
                            color: "#94a3b8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }
                    }

                    // Mini Progress Indicator
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: "#111c29"

                        Rectangle {
                            height: parent.height
                            radius: 3
                            width: Math.min(parent.width, Math.max(10, (root.cpuUsagePct / 100) * parent.width))
                            color: "#38bdf8"
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }
                    }
                }
            }

            // GPU Oberon Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                color: "#05090f"
                radius: 10
                border.color: "#122a22"
                border.width: 1

                Rectangle {
                    width: 3
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    color: "#00f0a8"
                    radius: 2
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    anchors.leftMargin: 14
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "GPU Oberon (40 CUs)"
                            color: "#e2e8f0"
                            font.family: "Plus Jakarta Sans"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "<font color='#00f0a8'><b>" + root.gpuDieTemp.toFixed(1) + "°C</b></font> · " + root.gpuSclkMhz + " / " + root.gpuMaxFreqMhz + " MHz"
                            textFormat: Text.RichText
                            color: "#94a3b8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }
                    }

                    // Mini Progress Indicator
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: "#0c1f19"

                        Rectangle {
                            height: parent.height
                            radius: 3
                            width: Math.min(parent.width, Math.max(10, (root.gpuBusyPct / 100) * parent.width))
                            color: "#00f0a8"
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }
                    }
                }
            }

            // GDDR6 Heatmap (8 Chips)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 88
                color: "#060a10"
                radius: 10
                border.color: "#182430"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "GDDR6 MEMÓRIA (8 CHIPS IC)"
                            color: "#94a3b8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "HOTSPOT: " + root.vramHotspotTemp.toFixed(1) + "°C (#" + root.vramHotspotChip + ")"
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
                                height: 40
                                radius: 5
                                property int chipTemp: (root.memoryChips && root.memoryChips.length > index) ? root.memoryChips[index] : 50
                                property bool isHotspot: (index === root.vramHotspotChip)
                                color: isHotspot ? "#33220c" : "#0d1622"
                                border.color: isHotspot ? "#f59e0b" : "#1c2938"
                                border.width: 1

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
                                        text: chipTemp + "°"
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

            // Power Stats Grid
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 8
                    color: "#0a121c"
                    border.color: "#192432"

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: "CONSUMO TOTAL"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8; Layout.alignment: Qt.AlignHCenter }
                        Text { text: root.totalPowerW.toFixed(0) + "W TDP"; color: "#ffffff"; font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 8
                    color: "#0a121c"
                    border.color: "#192432"

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: "TENSÃO RAIL 12V"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8; Layout.alignment: Qt.AlignHCenter }
                        Text { text: root.railVin.toFixed(2) + " V"; color: "#38bdf8"; font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 8
                    color: "#0a121c"
                    border.color: "#192432"

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: "VRM MOS TEMP"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8; Layout.alignment: Qt.AlignHCenter }
                        Text { text: root.vrmTemp.toFixed(1) + "°C"; color: "#f59e0b"; font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    }
                }
            }

            // Web Dashboard Button
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
                    Kirigami.Icon {
                        source: "arrow-up-right"
                        implicitWidth: 14
                        implicitHeight: 14
                        color: "#00f0a8"
                    }
                    Text {
                        text: "Abrir Cockpit Pro Web"
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
