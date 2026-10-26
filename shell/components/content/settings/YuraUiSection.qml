import QtQuick
import QtQuick.Layouts
import "../../common" as Common

Rectangle {
    id: section

    required property var theme
    required property var modeManager
    required property var settingsManager

    width: parent ? parent.width : 420
    height: contentColumn.implicitHeight + 24
    color: theme ? theme.surfaceInsetSubtle : Qt.rgba(0, 0, 0, 0.25)
    radius: 20
    border.width: 1
    border.color: theme ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2) : Qt.rgba(0.65, 0.55, 0.85, 0.2)

    readonly property var collapsePresets: [0, 1, 3, 5, 10]
    readonly property var speedOptions: ["instant", "fast", "normal", "slow"]

    function bump() {
        if (modeManager && modeManager.isMode("settings")) modeManager.bump()
    }

    function save() {
        if (settingsManager) settingsManager.saveSettings()
        section.bump()
    }

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Common.SettingLabel { theme: section.theme;
                title: "Idle orb breath"
                desc: "Slow breathing pulse on Yura's orb while idle"
            }

            Common.Switch {
                Layout.alignment: Qt.AlignVCenter
                checked: section.settingsManager ? section.settingsManager.yuraIdleBreath : false
                theme: section.theme

                onToggled: value => {
                    if (!section.settingsManager) return
                    section.settingsManager.yuraIdleBreath = value
                    section.save()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Common.SettingLabel { theme: section.theme;
                title: "Auto-collapse"
                desc: "Close the float panel after idle minutes"
            }

            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: section.collapsePresets

                    Common.Chip { theme: section.theme;
                        required property int modelData
                        label: modelData === 0 ? "Off" : modelData + "m"
                        selected: section.settingsManager
                            && section.settingsManager.yuraAutoCollapseMin === modelData
                        onClicked: {
                            if (!section.settingsManager) return
                            section.settingsManager.yuraAutoCollapseMin = modelData
                            section.save()
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Common.SettingLabel { theme: section.theme;
                title: "Typing speed"
                desc: "Typewriter reveal for streamed replies"
            }

            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: section.speedOptions

                    Common.Chip { theme: section.theme;
                        required property string modelData
                        label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                        selected: section.settingsManager
                            && section.settingsManager.yuraTypingSpeed === modelData
                        onClicked: {
                            if (!section.settingsManager) return
                            section.settingsManager.yuraTypingSpeed = modelData
                            section.save()
                        }
                    }
                }
            }
        }
    }
}
