import QtQuick
import QtQuick.Layouts
import "../../common" as Common

Rectangle {
    id: section

    required property var theme
    required property var modeManager
    required property var settingsManager

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

        ColumnLayout {
            Layout.fillWidth: true
            // Without a 0 minimum the long description pushes the pill off-screen.
            Layout.minimumWidth: 0
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: "Bar Yura thinking"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.weight: Font.Normal
                font.letterSpacing: 0.5
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: "Internal reasoning before reply (capable models only)"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.60)
                font.pixelSize: 10
                font.family: "M PLUS 2"
                opacity: 0.6
                elide: Text.ElideRight
            }
        }

        Common.Switch {
            Layout.alignment: Qt.AlignVCenter
            checked: section.settingsManager ? section.settingsManager.barThinking : false
            theme: section.theme

            onToggled: value => {
                if (!section.settingsManager) return
                section.settingsManager.barThinking = value
                section.settingsManager.saveSettings()
                section.bump()
            }
        }
    }
}
