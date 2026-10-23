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

    property string expandedSsid: ""
    property string connectingSsid: ""
    property string password: ""

    readonly property color danger: theme ? theme.danger : Qt.rgba(0.95, 0.45, 0.55, 1)
    readonly property bool powered: wifiManager ? wifiManager.isPowered : false
    readonly property var networks: {
        if (!wifiManager) return []
        return wifiManager.availableNetworks.slice().sort((a, b) =>
            (isCurrent(b.ssid) - isCurrent(a.ssid)) || (b.signal - a.signal))
    }
    readonly property string status: {
        if (!powered) return "Off"
        return wifiManager.isConnected ? "Connected to " + wifiManager.currentSsid : "Not connected"
    }

    width: parent ? parent.width : 420
    implicitHeight: body.implicitHeight + 24
    color: theme ? theme.surfaceInsetSubtle : Qt.rgba(0, 0, 0, 0.25)
    radius: 20
    border.width: 1
    border.color: theme ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2) : Qt.rgba(0.65, 0.55, 0.85, 0.2)

    function bump() {
        if (modeManager && modeManager.isMode("settings")) modeManager.bump()
    }

    function isCurrent(ssid) {
        return !!wifiManager && wifiManager.isConnected && wifiManager.currentSsid === ssid
    }

    Component.onCompleted: Qt.callLater(() => {
        if (section.wifiManager) section.wifiManager.fullRefresh()
    })

    Connections {
        target: section.wifiManager

        function onIsConnectingChanged() {
            if (section.wifiManager.isConnecting) return
            if (section.wifiManager.connectionError !== "") {
                if (section.connectingSsid !== "") section.expandedSsid = section.connectingSsid
            } else {
                section.connectingSsid = ""
                section.expandedSsid = ""
                section.wifiManager.refreshSavedNetworks()
            }
        }
    }

    Theme.IconProvider { id: icons }

    Component {
        id: networkRow

        Item {
            id: item

            required property var modelData

            readonly property var profile: section.wifiManager
                ? section.wifiManager.savedNetworks.find(p => p.ssid === modelData.ssid) : undefined
            readonly property bool isSaved: !!profile
            readonly property bool connected: section.isCurrent(modelData.ssid)
            readonly property bool expanded: section.expandedSsid === modelData.ssid && !connected
            readonly property bool connectingThis: section.wifiManager.isConnecting
                && section.connectingSsid === modelData.ssid
            readonly property bool showsError: section.wifiManager.connectionError !== ""
                && section.connectingSsid === modelData.ssid
            readonly property bool failed: showsError && !connected
            property bool reveal: false

            width: ListView.view.width
            height: column.implicitHeight

            function join() {
                if (passwordInput.text.length === 0 || section.wifiManager.isConnecting) return
                section.connectingSsid = modelData.ssid
                section.wifiManager.connectToNetwork(modelData.ssid, passwordInput.text)
                section.password = ""
                section.bump()
            }

            ColumnLayout {
                id: column
                width: parent.width
                spacing: 0

                ConnectivityRow {
                    Layout.fillWidth: true
                    theme: section.theme
                    icon: icons.wifiSvg
                    active: item.connected
                    hasError: item.failed
                    title: item.modelData.ssid
                    detail: {
                        if (item.failed) return section.wifiManager.connectionError
                        const kind = item.connected ? "Connected" : item.isSaved ? "Saved"
                            : item.modelData.secured ? "Secured" : "Open"
                        return kind + " · " + item.modelData.signal + "%"
                    }

                    Common.ActionButton {
                        theme: section.theme
                        buttonWidth: 84
                        label: item.connected ? "Disconnect"
                            : item.connectingThis ? "Connecting…"
                            : item.expanded ? "Cancel" : "Connect"
                        enabled: item.connected
                            ? !section.wifiManager.isModifyingConnection
                            : !section.wifiManager.isConnecting
                        opacity: enabled ? 1 : 0.45
                        onClicked: {
                            if (item.connected) {
                                section.wifiManager.disconnectWifi()
                            } else if (item.expanded) {
                                section.expandedSsid = ""
                            } else if (item.isSaved) {
                                section.connectingSsid = item.modelData.ssid
                                section.wifiManager.connectSavedNetwork(item.profile)
                            } else if (item.modelData.secured) {
                                section.password = ""
                                section.expandedSsid = item.modelData.ssid
                            } else {
                                section.connectingSsid = item.modelData.ssid
                                section.wifiManager.connectToNetwork(item.modelData.ssid, "")
                            }
                            section.bump()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 6
                    Layout.topMargin: 2
                    Layout.bottomMargin: 6
                    visible: item.expanded
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        color: "transparent"
                        radius: 8
                        border.width: 1
                        border.color: passwordInput.activeFocus
                            ? (section.theme ? section.theme.glowPrimary : Qt.rgba(0.65, 0.55, 0.85, 1))
                            : (section.theme ? section.theme.surfaceBorder : Qt.rgba(1, 1, 1, 0.18))
                        Behavior on border.color { ColorAnimation { duration: Theme.Motion.fast } }

                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            color: section.theme ? section.theme.textPrimary : Qt.rgba(0.91, 0.91, 0.94, 0.9)
                            selectionColor: section.theme
                                ? Qt.rgba(section.theme.glowPrimary.r, section.theme.glowPrimary.g, section.theme.glowPrimary.b, 0.4)
                                : Qt.rgba(0.65, 0.55, 0.85, 0.4)
                            font.pixelSize: 12
                            font.family: "M PLUS 2"
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: item.reveal ? TextInput.Normal : TextInput.Password
                            clip: true
                            text: section.password
                            onTextEdited: {
                                section.password = text
                                section.bump()
                            }
                            Keys.onReturnPressed: item.join()
                            Keys.onEnterPressed: item.join()

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Password"
                                color: section.theme ? section.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.5)
                                font: passwordInput.font
                                opacity: passwordInput.text.length === 0 ? 0.5 : 0
                            }
                        }
                    }

                    Common.ActionButton {
                        theme: section.theme
                        buttonWidth: 56
                        label: item.reveal ? "Hide" : "Show"
                        onClicked: {
                            item.reveal = !item.reveal
                            section.bump()
                        }
                    }

                    Common.ActionButton {
                        theme: section.theme
                        buttonWidth: 72
                        label: item.connectingThis ? "Joining…" : "Join"
                        enabled: passwordInput.text.length > 0 && !section.wifiManager.isConnecting
                        opacity: enabled ? 1 : 0.45
                        onClicked: item.join()
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 12

            Common.SettingLabel {
                theme: section.theme
                title: "Wi-Fi"
                desc: section.status
            }

            Common.Switch {
                theme: section.theme
                checked: section.powered
                enabled: section.wifiManager ? !section.wifiManager.isTogglingPower : false
                onToggled: {
                    if (section.wifiManager) section.wifiManager.togglePower()
                    section.bump()
                }
            }
        }

        ConnectivityList {
            Layout.fillWidth: true
            visible: section.powered
            theme: section.theme
            model: section.networks
            rowDelegate: networkRow
            maxHeight: 240
            placeholder: section.wifiManager && section.wifiManager.isRefreshing
                ? "Searching for networks…" : "No networks found"
        }

        RowLayout {
            Layout.fillWidth: true
            visible: section.powered
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: section.networks.length === 1 ? "1 network nearby" : section.networks.length + " networks nearby"
                color: section.theme ? section.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.60)
                font.pixelSize: 10
                font.family: "M PLUS 2"
                font.letterSpacing: 0.3
                wrapMode: Text.WordWrap
            }

            Common.ActionButton {
                theme: section.theme
                buttonWidth: 84
                label: section.wifiManager && section.wifiManager.isRefreshing ? "Scanning…" : "Scan"
                enabled: section.wifiManager ? !section.wifiManager.isRefreshing : false
                opacity: enabled ? 1 : 0.45
                onClicked: {
                    section.wifiManager.fullRefresh()
                    section.bump()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: section.powered && text !== ""
            text: section.wifiManager ? section.wifiManager.actionError : ""
            color: section.danger
            font.pixelSize: 10
            font.family: "M PLUS 2"
            wrapMode: Text.WordWrap
        }
    }
}
