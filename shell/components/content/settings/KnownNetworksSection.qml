pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../common" as Common
import "../../../lib" as Theme

Rectangle {
    id: section

    required property var theme
    required property var modeManager
    required property var wifiManager

    property bool isExpanded: false

    readonly property color danger: theme ? theme.danger : Qt.rgba(0.95, 0.45, 0.55, 1)
    readonly property var saved: wifiManager ? wifiManager.savedNetworks : []
    readonly property int expandedHeight: 64 + contentColumn.implicitHeight + 16

    width: parent ? parent.width : 420
    height: isExpanded ? expandedHeight : 64
    color: theme ? theme.surfaceInsetSubtle : Qt.rgba(0, 0, 0, 0.25)
    radius: 20
    border.width: 1
    border.color: theme ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2) : Qt.rgba(0.65, 0.55, 0.85, 0.2)
    clip: true

    function bump() {
        if (modeManager && modeManager.isMode("settings")) modeManager.bump()
    }

    function summary() {
        if (saved.length === 0) return "None"
        return saved.length === 1 ? "1 network" : saved.length + " networks"
    }

    Behavior on height {
        NumberAnimation { duration: Theme.Motion.standard; easing.type: Easing.OutCubic }
    }

    Theme.IconProvider { id: icons }

    Component {
        id: savedRow

        ConnectivityRow {
            id: row

            required property var modelData

            property bool armed: false
            readonly property bool busy: section.wifiManager.isModifyingConnection
            readonly property bool connected: section.wifiManager.isConnected
                && section.wifiManager.currentSsid === modelData.ssid

            width: ListView.view.width
            theme: section.theme
            icon: icons.wifiSvg
            active: connected
            title: modelData.ssid || modelData.name
            detail: connected ? "Connected"
                : modelData.autoConnect ? "Joins automatically" : "Joins only when you pick it"

            Timer {
                id: disarmTimer
                interval: 5000
                onTriggered: row.armed = false
            }

            Text {
                text: "Auto-join"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 10
                font.family: "M PLUS 2"
                opacity: 0.8
            }

            Common.Switch {
                theme: section.theme
                scale: 0.8
                checked: row.modelData.autoConnect
                enabled: !row.busy
                onToggled: value => {
                    section.wifiManager.setNetworkAutoConnect(row.modelData, value)
                    section.bump()
                }
            }

            Common.ActionButton {
                theme: section.theme
                buttonWidth: 72
                label: row.armed ? "Confirm" : "Forget"
                tint: Qt.rgba(section.danger.r, section.danger.g, section.danger.b, row.armed ? 0.34 : 0.16)
                tintHover: Qt.rgba(section.danger.r, section.danger.g, section.danger.b, row.armed ? 0.46 : 0.28)
                enabled: !row.busy
                onClicked: {
                    if (!row.armed) {
                        row.armed = true
                        disarmTimer.restart()
                    } else {
                        row.armed = false
                        disarmTimer.stop()
                        section.wifiManager.forgetNetwork(row.modelData)
                    }
                    section.bump()
                }
            }
        }
    }

    MouseArea {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 64
        cursorShape: Qt.PointingHandCursor

        TapHandler {
            onTapped: {
                section.isExpanded = !section.isExpanded
                section.bump()
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Common.SettingLabel {
                theme: section.theme
                title: "Known networks"
                desc: "Networks this computer has joined before"
            }

            Text {
                text: section.summary()
                color: section.theme ? section.theme.textPrimary : Qt.rgba(0.92, 0.92, 0.96, 0.90)
                font.pixelSize: 11
                font.family: "M PLUS 2"
                opacity: 0.85
            }

            Text {
                text: section.isExpanded ? "▴" : "▾"
                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                opacity: 0.7
            }
        }
    }

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 4
        spacing: 10
        visible: section.isExpanded

        ConnectivityList {
            Layout.fillWidth: true
            theme: section.theme
            model: section.saved
            rowDelegate: savedRow
            maxHeight: 240
            placeholder: "No saved networks"
        }

        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: section.wifiManager ? section.wifiManager.actionError : ""
            color: section.danger
            font.pixelSize: 10
            font.family: "M PLUS 2"
            wrapMode: Text.WordWrap
        }
    }
}
