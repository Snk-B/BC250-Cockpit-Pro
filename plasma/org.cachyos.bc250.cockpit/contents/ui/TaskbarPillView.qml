import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: pillRoot
    implicitWidth: pillLayout.implicitWidth + 24
    implicitHeight: Math.min(36, parent ? parent.height - 8 : 32)
    Layout.fillHeight: true

    // Smooth animated values
    property real displayCpuTemp: root.cpuDieTemp
    Behavior on displayCpuTemp { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }

    property real displayGpuTemp: root.gpuDieTemp
    Behavior on displayGpuTemp { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }

    property real displayVrmTemp: root.vrmTemp
    Behavior on displayVrmTemp { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }

    Rectangle {
        id: pillBg
        anchors.fill: parent
        anchors.margins: 2
        radius: height / 2
        color: pillMouse.containsMouse ? "#162235" : "#0d1622"
        border.color: pillMouse.containsMouse ? "#00f0a8" : "#264f43"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: pillLayout
            anchors.centerIn: parent
            spacing: 8

            // Glowing Indicator Dot
            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: "#00f0a8"
                Layout.alignment: Qt.AlignVCenter

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    PropertyAnimation { to: 0.4; duration: 900; easing.type: Easing.InOutQuad }
                    PropertyAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                }
            }

            // Board Label
            Text {
                text: "BC-250"
                color: "#ffffff"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle { width: 1; height: 12; color: "#ffffff"; opacity: 0.15; Layout.alignment: Qt.AlignVCenter }

            // CPU Stat
            Text {
                text: "<font color='#64748b'>CPU:</font> <font color='#38bdf8'><b>" + pillRoot.displayCpuTemp.toFixed(1) + "°C</b></font> <font color='#94a3b8' size='-1'>(" + root.cpuFreqMhz + " MHz)</font>"
                textFormat: Text.RichText
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle { width: 1; height: 12; color: "#ffffff"; opacity: 0.15; Layout.alignment: Qt.AlignVCenter }

            // GPU Stat
            Text {
                text: "<font color='#64748b'>GPU:</font> <font color='#00f0a8'><b>" + pillRoot.displayGpuTemp.toFixed(1) + "°C</b></font> <font color='#94a3b8' size='-1'>(" + root.gpuSclkMhz + " MHz)</font>"
                textFormat: Text.RichText
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle { width: 1; height: 12; color: "#ffffff"; opacity: 0.15; Layout.alignment: Qt.AlignVCenter }

            // VRM Stat
            Text {
                text: "<font color='#64748b'>VRM:</font> <font color='#f59e0b'><b>" + pillRoot.displayVrmTemp.toFixed(1) + "°C</b></font>"
                textFormat: Text.RichText
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle { width: 1; height: 12; color: "#ffffff"; opacity: 0.15; Layout.alignment: Qt.AlignVCenter }

            // Fan Stat
            Text {
                text: "<font color='#64748b'>FAN:</font> <font color='#f1f5f9'><b>" + root.fanRpm + " RPM</b></font>"
                textFormat: Text.RichText
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
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
