import QtQuick
import QtQuick.Layouts

Item {
    id: pillRoot

    // Fixed Dimensions matching the calibrated anti-jitter slot (352 x 32 px)
    readonly property real fixedPillWidth: 352
    readonly property real fixedPillHeight: Math.min(36, parent ? parent.height - 8 : 32)

    implicitWidth: fixedPillWidth
    implicitHeight: fixedPillHeight
    width: fixedPillWidth
    height: fixedPillHeight

    Layout.minimumWidth: fixedPillWidth
    Layout.preferredWidth: fixedPillWidth
    Layout.maximumWidth: fixedPillWidth
    Layout.fillWidth: false
    Layout.fillHeight: true

    Rectangle {
        id: pillBg
        anchors.fill: parent
        anchors.margins: 2
        radius: height / 2
        color: (root.isCpuOverclock || root.isGpuOverclock) ? (pillMouse.containsMouse ? "#2a1410" : "#1c0d0a") : (pillMouse.containsMouse ? "#162235" : "#0d1622")
        border.color: (root.isCpuOverclock || root.isGpuOverclock) ? "#ff4500" : (pillMouse.containsMouse ? "#00f0a8" : "#264f43")
        border.width: 1

        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }

        RowLayout {
            id: pillLayout
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 4

            // 1. IDENTIDADE (Largura Fixa: 44 px)
            RowLayout {
                id: modIdent
                Layout.preferredWidth: 44
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                Rectangle {
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: (root.isCpuOverclock || root.isGpuOverclock) ? "#ff4500" : "#00f0a8"
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color { ColorAnimation { duration: 250 } }

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        PropertyAnimation { to: 0.4; duration: (root.isCpuOverclock || root.isGpuOverclock) ? 450 : 900; easing.type: Easing.InOutQuad }
                        PropertyAnimation { to: 1.0; duration: (root.isCpuOverclock || root.isGpuOverclock) ? 450 : 900; easing.type: Easing.InOutQuad }
                    }
                }

                Text {
                    text: "BC-250"
                    color: "#ffffff"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Divisor 1
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 14
                color: (root.isCpuOverclock || root.isGpuOverclock) ? "#5c1d12" : "#264f43"
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            // 2. CPU (Largura Calibrada para 4 digitos com espacamento sem oscilacao)
            ColumnLayout {
                id: modCpu
                Layout.preferredWidth: 58
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    text: "<font color='" + (root.isCpuOverclock ? "#ff4500" : "#64748b") + "'>" + (root.isCpuOverclock ? "OC " : "CPU") + "</font> <font color='" + (root.isCpuOverclock ? "#ff4500" : "#ffffff") + "'><b>" + Math.round(root.smoothCpuFreqMhz) + "</b></font> <font color='#64748b'>MHz</font>"
                    textFormat: Text.RichText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    Layout.alignment: Qt.AlignLeft
                }
                Text {
                    text: "<font color='#64748b'>TMP</font> <font color='" + (root.isCpuOverclock ? "#ff7849" : "#38bdf8") + "'><b>" + root.smoothCpuDieTemp.toFixed(1) + "\u00B0C</b></font>"
                    textFormat: Text.RichText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    Layout.alignment: Qt.AlignLeft
                }
            }

            // Divisor 2
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 14
                color: (root.isCpuOverclock || root.isGpuOverclock) ? "#5c1d12" : "#264f43"
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            // 3. GPU (Largura Calibrada para 4 digitos com espacamento sem oscilacao)
            ColumnLayout {
                id: modGpu
                Layout.preferredWidth: 58
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    text: "<font color='" + (root.isGpuOverclock ? "#ff3300" : "#64748b") + "'>" + (root.isGpuOverclock ? "OC " : "GPU") + "</font> <font color='" + (root.isGpuOverclock ? "#ff3300" : "#ffffff") + "'><b>" + Math.round(root.smoothGpuSclkMhz) + "</b></font> <font color='#64748b'>MHz</font>"
                    textFormat: Text.RichText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    Layout.alignment: Qt.AlignLeft
                }
                Text {
                    text: "<font color='#64748b'>TMP</font> <font color='" + (root.isGpuOverclock ? "#ff5252" : "#00f0a8") + "'><b>" + root.smoothGpuDieTemp.toFixed(1) + "\u00B0C</b></font>"
                    textFormat: Text.RichText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    Layout.alignment: Qt.AlignLeft
                }
            }

            // Divisor 3
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 14
                color: "#264f43"
                Layout.alignment: Qt.AlignVCenter
            }

            // 4. VRM + SMU (Largura Fixa: 62 px - Calibrada para 3 digitos de Watts e Temps)
            ColumnLayout {
                id: modVrm
                Layout.preferredWidth: 62
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    text: "<font color='#64748b'>VRM</font> <font color='#f59e0b'><b>" + root.smoothVrmTemp.toFixed(1) + "\u00B0C</b></font>"
                    textFormat: Text.RichText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    Layout.alignment: Qt.AlignLeft
                }
                Text {
                    text: "<font color='#64748b'>SMU</font> <font color='#fde047'><b>" + Math.round(root.smoothTotalPowerW) + "W PWR</b></font>"
                    textFormat: Text.RichText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    Layout.alignment: Qt.AlignLeft
                }
            }

            // Divisor 4
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 14
                color: "#264f43"
                Layout.alignment: Qt.AlignVCenter
            }

            // 5. COOLING FAN + PWM (Largura Calibrada para 4 digitos de RPM e '100% ATIVO')
            ColumnLayout {
                id: modFan
                Layout.preferredWidth: 74
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    text: "<font color='#64748b'>FAN</font> <font color='#ffffff'><b>" + Math.round(root.smoothFanRpm) + "</b></font> <font color='#64748b'>RPM</font>"
                    textFormat: Text.RichText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    Layout.alignment: Qt.AlignLeft
                }
                Text {
                    text: "<font color='#64748b'>PWM</font> <font color='#38bdf8'><b>" + Math.round(root.smoothFanPwmPct) + "% " + (root.isPortuguese ? "ATIVO" : "ACTIVE") + "</b></font>"
                    textFormat: Text.RichText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    Layout.alignment: Qt.AlignLeft
                }
            }
        }
    }

    MouseArea {
        id: pillMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.expanded = !root.expanded
        }
    }
}
