import QtQuick
import QtQuick.Layouts
import "../../common" as Common

Rectangle {
    id: section

    required property var theme
    required property var modeManager
    required property var settingsManager

    readonly property bool slideshowOn: settingsManager ? settingsManager.wallpaperSlideshow : false
    readonly property var minuteOptions: [
        { label: "1 min", value: 1 },
        { label: "5 min", value: 5 },
        { label: "10 min", value: 10 },
        { label: "15 min", value: 15 },
        { label: "30 min", value: 30 },
        { label: "60 min", value: 60 }
    ]
    readonly property var orderOptions: [
        { label: "Shuffle", value: "shuffle" },
        { label: "In order", value: "inOrder" }
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

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Common.SettingLabel {
                theme: section.theme
                title: "Slideshow"
                desc: "Rotates through your wallpaper folder; colors follow each wallpaper"
            }

            Common.Switch {
                checked: section.slideshowOn
                theme: section.theme
                onToggled: value => {
                    if (!section.settingsManager) return
                    section.settingsManager.wallpaperSlideshow = value
                    section.save()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 12
            enabled: section.slideshowOn
            opacity: enabled ? 1 : 0.35

            Text {
                Layout.fillWidth: true
                text: "Every"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.letterSpacing: 0.5
            }

            Common.ChoiceChips {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                theme: section.theme
                options: section.minuteOptions
                current: section.settingsManager ? section.settingsManager.wallpaperSlideshowMinutes : 0
                onPicked: value => {
                    if (!section.settingsManager) return
                    section.settingsManager.wallpaperSlideshowMinutes = value
                    section.save()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 12
            enabled: section.slideshowOn
            opacity: enabled ? 1 : 0.35

            Text {
                Layout.fillWidth: true
                text: "Order"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.letterSpacing: 0.5
            }

            Common.ChoiceChips {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                theme: section.theme
                options: section.orderOptions
                current: section.settingsManager ? section.settingsManager.wallpaperSlideshowOrder : ""
                onPicked: value => {
                    if (!section.settingsManager) return
                    section.settingsManager.wallpaperSlideshowOrder = value
                    section.save()
                }
            }
        }
    }
}
