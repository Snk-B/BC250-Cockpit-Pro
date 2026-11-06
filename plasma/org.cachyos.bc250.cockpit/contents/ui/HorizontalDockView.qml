import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: dockRoot
    implicitWidth: 640
    implicitHeight: 140

    Rectangle {
        anchors.fill: parent
        color: "#0a101a"
        radius: 18
        border.color: "#1c3c4f"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Kirigami.Icon {
                    source: "computer-symbolic"
                    implicitWidth: 16
                    implicitHeight: 16
                    color: "#38bdf8"
                }

                Text {
                    text: "BC-250 OBERON · DOCK COMPACTO"
                    color: "#ffffff"
                    font.family: "Plus Jakarta Sans"
                    font.pixelSize: 12
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.kernelRelease
                    color: "#38bdf8"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff"; opacity: 0.08 }

            // 4 Tiles Grid
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Tile 1: CPU DIE
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 68
                    color: "#070c14"
                    radius: 10
                    border.color: "#142533"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2
                        Text { text: "CPU ZEN 2 DIE"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8; font.bold: true }
                        Text {
                            text: "<font color='#38bdf8'><b>" + root.cpuDieTemp.toFixed(1) + "</b></font><font color='#fde047' size='-1'>°C</font>"
                            textFormat: Text.RichText
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Text { text: "8c/16t · " + root.cpuUsagePct.toFixed(0) + "% Load"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                    }
                }

                // Tile 2: GPU DIE
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 68
                    color: "#070c14"
                    radius: 10
                    border.color: "#11261e"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2
                        Text { text: "GPU RDNA2 DIE"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8; font.bold: true }
                        Text {
                            text: "<font color='#00f0a8'><b>" + root.gpuDieTemp.toFixed(1) + "</b></font><font color='#fde047' size='-1'>°C</font>"
                            textFormat: Text.RichText
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Text { text: "40 CUs · " + root.gpuBusyPct.toFixed(0) + "% Load"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                    }
                }

                // Tile 3: VRM HOTSPOT
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 68
                    color: "#070c14"
                    radius: 10
                    border.color: "#281e11"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2
                        Text { text: "VRM HOTSPOT"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8; font.bold: true }
                        Text {
                            text: "<font color='#f59e0b'><b>" + root.vrmTemp.toFixed(1) + "</b></font><font color='#fde047' size='-1'>°C</font>"
                            textFormat: Text.RichText
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Text { text: "DrMOS · " + root.totalPowerW.toFixed(0) + "W TDP"; color: "#94a3b8"; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                    }
                }

                // Tile 4: Dual Line Frequencies
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 68
                    color: "#070c14"
                    radius: 10
                    border.color: "#182430"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 3
                        Text { text: "FREQUÊNCIAS ATIVAS"; color: "#64748b"; font.family: "JetBrains Mono"; font.pixelSize: 8; font.bold: true }

                        RowLayout {
                            Layout.fillWidth: true
                            Rectangle { width: 24; height: 14; radius: 3; color: "#122a38"; border.color: "#20465c"; Text { anchors.centerIn: parent; text: "CPU"; color: "#38bdf8"; font.family: "JetBrains Mono"; font.pixelSize: 8; font.bold: true } }
                            Text { text: root.cpuFreqMhz + " <font color='#64748b' size='-2'>/ " + root.cpuTargetFreqMhz + "</font>"; textFormat: Text.RichText; color: "#ffffff"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Rectangle { width: 24; height: 14; radius: 3; color: "#0d261e"; border.color: "#194d3d"; Text { anchors.centerIn: parent; text: "GPU"; color: "#00f0a8"; font.family: "JetBrains Mono"; font.pixelSize: 8; font.bold: true } }
                            Text { text: root.gpuSclkMhz + " <font color='#64748b' size='-2'>/ " + root.gpuMaxFreqMhz + "</font>"; textFormat: Text.RichText; color: "#ffffff"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                        }
                    }
                }
            }
        }
    }
}
