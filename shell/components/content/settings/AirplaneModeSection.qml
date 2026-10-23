import QtQuick
import QtQuick.Layouts
import "../../common" as Common

Rectangle {
    id: section

    required property var theme
    required property var modeManager
    required property var airplaneManager

    readonly property bool isOn: airplaneManager ? airplaneManager.isEnabled : false

    width: parent ? parent.width : 420
    height: 64
    color: theme ? theme.surfaceInsetSubtle : Qt.rgba(0, 0, 0, 0.25)
    radius: 20
    border.width: 1
    border.color: theme ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2) : Qt.rgba(0.65, 0.55, 0.85, 0.2)

    function bump() {
        if (modeManager && modeManager.isMode("settings")) modeManager.bump()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Common.SettingLabel {
            theme: section.theme
            title: "Airplane mode"
            desc: section.isOn ? "Wireless radios are off" : "Turns off Wi-Fi and Bluetooth"
        }

        Common.Switch {
            theme: section.theme
            checked: section.isOn
            enabled: section.airplaneManager ? !section.airplaneManager.airplaneToggleProcess.running : false
            onToggled: {
                if (section.airplaneManager) section.airplaneManager.toggle()
                section.bump()
            }
        }
    }
}
