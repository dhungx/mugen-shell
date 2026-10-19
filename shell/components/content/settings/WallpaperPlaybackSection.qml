import QtQuick
import QtQuick.Layouts
import "../../common" as Common
import "../../../lib" as Theme

Rectangle {
    id: section

    required property var theme
    required property var modeManager
    required property var settingsManager

    readonly property bool soundOn: settingsManager ? settingsManager.wallpaperSound : false
    readonly property var pauseWhenOptions: [
        { label: "Never", value: "never" },
        { label: "Fullscreen", value: "fullscreen" }
    ]

    width: parent ? parent.width : 420
    height: column.implicitHeight + 24
    color: theme ? theme.surfaceInsetSubtle : Qt.rgba(0, 0, 0, 0.25)
    radius: 20
    border.width: 1
    border.color: theme ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2) : Qt.rgba(0.65, 0.55, 0.85, 0.2)

    function bump() {
        if (modeManager && modeManager.isMode("settings")) modeManager.bump()
    }

    function save() {
        if (settingsManager) settingsManager.saveSettings()
        bump()
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Common.SettingLabel {
            theme: section.theme
            title: "Video playback"
            desc: "Applies to video wallpapers"
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Pause when"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.letterSpacing: 0.5
            }

            Common.ChoiceChips {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                theme: section.theme
                options: section.pauseWhenOptions
                current: section.settingsManager ? section.settingsManager.wallpaperPauseWhen : ""
                onPicked: value => {
                    if (!section.settingsManager) return
                    section.settingsManager.wallpaperPauseWhen = value
                    section.save()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Speed"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.letterSpacing: 0.5
            }

            Common.Slider {
                Layout.preferredWidth: 180
                theme: section.theme
                from: 1
                to: 8
                stepSize: 1
                value: section.settingsManager ? section.settingsManager.wallpaperSpeed * 4 : 4
                display: Theme.WallpaperRules.speedLabel(value / 4)

                onMoved: nv => {
                    if (section.settingsManager) section.settingsManager.wallpaperSpeed = Math.round(nv) / 4
                    section.bump()
                }
                onReleased: section.save()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Sound"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.letterSpacing: 0.5
            }

            Common.Switch {
                checked: section.soundOn
                theme: section.theme
                onToggled: value => {
                    if (!section.settingsManager) return
                    section.settingsManager.wallpaperSound = value
                    section.save()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 12
            enabled: section.soundOn
            opacity: enabled ? 1 : 0.35

            Text {
                Layout.fillWidth: true
                text: "Volume"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.letterSpacing: 0.5
            }

            Common.Slider {
                Layout.preferredWidth: 180
                theme: section.theme
                from: 0
                to: 100
                stepSize: 1
                value: section.settingsManager ? section.settingsManager.wallpaperVolume : 50
                display: Math.round(value) + "%"

                onMoved: nv => {
                    if (section.settingsManager) section.settingsManager.wallpaperVolume = Math.round(nv)
                    section.bump()
                }
                onReleased: section.save()
            }
        }
    }
}
