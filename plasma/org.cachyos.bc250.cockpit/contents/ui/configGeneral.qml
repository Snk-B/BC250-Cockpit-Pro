import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_desktopLayout: desktopLayoutCombo.currentIndex
    property alias cfg_pollInterval: pollIntervalSpin.value
    property alias cfg_serverUrl: serverUrlField.text

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: desktopLayoutCombo
            Kirigami.FormData.label: "Modo na Área de Trabalho:"
            model: [
                "Desktop HUD Completo (3 Círculos Térmicos + Matriz)",
                "Dock Horizontal Compacta (4 Cards de Telemetria)"
            ]
        }

        QQC2.SpinBox {
            id: pollIntervalSpin
            Kirigami.FormData.label: "Intervalo de Polling (ms):"
            from: 250
            to: 5000
            stepSize: 100
        }

        QQC2.TextField {
            id: serverUrlField
            Kirigami.FormData.label: "Servidor Cockpit Pro:"
            placeholderText: "http://127.0.0.1:8090"
        }
    }
}
