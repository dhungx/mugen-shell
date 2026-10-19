import QtQuick
import QtQuick.Layouts
import "../../common" as Common
import "../../../lib" as Theme

Rectangle {
    id: section

    required property var theme
    required property var modeManager
    required property var settingsManager

    readonly property var fitOptions: [
        { label: "Fill", value: "fill" },
        { label: "Fit", value: "fit" },
        { label: "Stretch", value: "stretch" }
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
            title: "Display"
            desc: "Applies to images and videos"
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Fit"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.letterSpacing: 0.5
            }

            Common.ChoiceChips {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                theme: section.theme
                options: section.fitOptions
                current: section.settingsManager ? section.settingsManager.wallpaperFit : ""
                onPicked: value => {
                    if (!section.settingsManager) return
                    section.settingsManager.wallpaperFit = value
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
                text: "Brightness"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.letterSpacing: 0.5
            }

            Common.Slider {
                Layout.preferredWidth: 180
                theme: section.theme
                from: -50
                to: 50
                stepSize: 1
                value: section.settingsManager ? section.settingsManager.wallpaperBrightness : 0
                display: (value > 0 ? "+" : "") + value

                onMoved: nv => {
                    if (section.settingsManager) section.settingsManager.wallpaperBrightness = Theme.WallpaperRules.roundHalfAway(nv)
                    section.bump()
                }
                onReleased: section.save()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Saturation"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.letterSpacing: 0.5
            }

            Common.Slider {
                Layout.preferredWidth: 180
                theme: section.theme
                from: -100
                to: 100
                stepSize: 1
                value: section.settingsManager ? section.settingsManager.wallpaperSaturation : 0
                display: (value > 0 ? "+" : "") + value

                onMoved: nv => {
                    if (section.settingsManager) section.settingsManager.wallpaperSaturation = Theme.WallpaperRules.roundHalfAway(nv)
                    section.bump()
                }
                onReleased: section.save()
            }
        }
    }
}
