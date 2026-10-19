import QtQuick
import QtQuick.Layouts
import "../../common" as Common
import "../../../lib" as Theme

Rectangle {
    id: section

    required property var theme
    required property var modeManager
    required property var settingsManager

    readonly property bool animated: settingsManager ? settingsManager.wallpaperTransition !== "none" : true
    readonly property var effectOptions: [
        { label: "Wave", value: "wave" },
        { label: "Fade", value: "fade" },
        { label: "Wipe", value: "wipe" },
        { label: "Grow", value: "grow" },
        { label: "Random", value: "random" },
        { label: "None", value: "none" }
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

        Text {
            Layout.fillWidth: true
            text: "Transition"
            color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
            font.pixelSize: 12
            font.family: "M PLUS 2"
            font.letterSpacing: 0.5
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Effect"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.letterSpacing: 0.5
            }

            Common.ChoiceChips {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                theme: section.theme
                options: section.effectOptions
                current: section.settingsManager ? section.settingsManager.wallpaperTransition : ""
                onPicked: value => {
                    if (!section.settingsManager) return
                    section.settingsManager.wallpaperTransition = value
                    section.save()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 12
            enabled: section.animated
            opacity: enabled ? 1 : 0.35

            Text {
                Layout.fillWidth: true
                text: "Duration"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.letterSpacing: 0.5
            }

            Common.Slider {
                Layout.preferredWidth: 180
                theme: section.theme
                from: 0.3
                to: 3.0
                stepSize: 0.1
                value: section.settingsManager ? section.settingsManager.wallpaperTransitionSeconds : 1.3
                display: value.toFixed(1) + " s"

                onMoved: nv => {
                    if (section.settingsManager) section.settingsManager.wallpaperTransitionSeconds = Theme.WallpaperRules.roundHalfAway(nv * 10) / 10
                    section.bump()
                }
                onReleased: section.save()
            }
        }
    }
}
