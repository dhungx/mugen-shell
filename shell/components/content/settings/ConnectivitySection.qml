import QtQuick
import QtQuick.Layouts
import "../../ui" as UI
import "../../common" as Common
import "../../../lib" as Theme

ColumnLayout {
    id: root

    required property var theme
    required property var modeManager
    required property var wifiManager
    required property var bluetoothManager
    required property var airplaneManager

    width: parent ? parent.width : 420
    spacing: 18

    property int expandedNetworkIndex: -1
    property string connectingSsid: ""
    property int connectingHint: -1
    property int pairingDeviceIndex: -1
    property bool savedNetworksExpanded: false

    readonly property int connectingNetworkIndex: {
        const nets = wifiManager ? wifiManager.availableNetworks : []
        if (connectingSsid === "") return -1
        const hinted = nets[connectingHint]
        return hinted && hinted.ssid === connectingSsid ? connectingHint
            : nets.findIndex(net => net.ssid === connectingSsid)
    }
    readonly property color cardFill: theme ? theme.surfaceInsetSubtle : Qt.rgba(0, 0, 0, 0.25)
    readonly property color cardBorder: theme ? Qt.rgba(theme.surfaceBorder.r, theme.surfaceBorder.g, theme.surfaceBorder.b, 0.45) : Qt.rgba(1, 1, 1, 0.12)
    readonly property color divider: theme ? Qt.rgba(theme.surfaceBorder.r, theme.surfaceBorder.g, theme.surfaceBorder.b, 0.35) : Qt.rgba(1, 1, 1, 0.10)

    function bump() {
        if (modeManager && modeManager.isMode("settings")) modeManager.bump()
    }

    function refreshAll() {
        if (wifiManager) wifiManager.fullRefresh()
        if (bluetoothManager) bluetoothManager.refreshStatus()
        if (airplaneManager) airplaneManager.refreshStatus()
    }

    Connections {
        target: root.wifiManager
        function onIsConnectingChanged() {
            if (root.wifiManager.isConnecting) return
            if (root.wifiManager.connectionError !== "") {
                if (root.connectingNetworkIndex >= 0)
                    root.expandedNetworkIndex = root.connectingNetworkIndex
            } else {
                root.connectingSsid = ""
                root.expandedNetworkIndex = -1
                root.wifiManager.refreshSavedNetworks()
            }
        }
    }

    Connections {
        target: root.bluetoothManager
        function onIsPairingChanged() {
            if (!root.bluetoothManager.isPairing) root.pairingDeviceIndex = -1
        }
    }

    Component.onCompleted: Qt.callLater(() => root.refreshAll())

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 3

        Text {
            text: "Wi-Fi & Bluetooth"
            color: root.theme ? root.theme.textPrimary : "white"
            font.pixelSize: 21
            font.weight: Font.DemiBold
            font.family: "M PLUS 2"
            font.letterSpacing: -0.3
        }

        Text {
            Layout.fillWidth: true
            text: "Manage your network connections and nearby devices."
            color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.9)
            font.pixelSize: 11
            font.family: "M PLUS 2"
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.airplaneManager ? root.airplaneManager.active : false
        implicitHeight: airplaneBody.implicitHeight + 20
        radius: 16
        color: root.cardFill
        border.width: 1
        border.color: root.cardBorder

        RowLayout {
            id: airplaneBody
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 11

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 11
                color: root.theme ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.14) : Qt.rgba(0.65, 0.55, 0.85, 0.14)
                UI.SvgIcon {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: connectivityIcons.airplaneSvg
                    color: root.theme ? root.theme.accent : "white"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "Airplane Mode"
                    color: root.theme ? root.theme.textPrimary : "white"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.family: "M PLUS 2"
                }
                Text {
                    text: root.airplaneManager && root.airplaneManager.isEnabled
                        ? "Wireless radios are turned off"
                        : "Wi-Fi and Bluetooth are available"
                    color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.8)
                    font.pixelSize: 10
                    font.family: "M PLUS 2"
                }
            }

            Common.Switch {
                checked: root.airplaneManager ? root.airplaneManager.isEnabled : false
                theme: root.theme
                enabled: root.airplaneManager && !root.airplaneManager.airplaneToggleProcess.running
                onToggled: root.airplaneManager.toggle()
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "WI-FI"
        color: root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8)
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1.2
        font.family: "M PLUS 2"
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: wifiHeader.implicitHeight + 20
        radius: 16
        color: root.cardFill
        border.width: 1
        border.color: root.cardBorder

        RowLayout {
            id: wifiHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 13
            spacing: 11

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 12
                color: root.theme ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.15) : Qt.rgba(0.25, 0.48, 0.95, 0.15)
                UI.SvgIcon {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    source: root.wifiManager && root.wifiManager.isPowered ? connectivityIcons.wifiSvg : connectivityIcons.wifiOffSvg
                    color: root.wifiManager && root.wifiManager.isPowered
                        ? (root.theme ? root.theme.accent : Qt.rgba(0.4, 0.65, 1, 1))
                        : (root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8))
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "Wi-Fi"
                    color: root.theme ? root.theme.textPrimary : "white"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    font.family: "M PLUS 2"
                }
                Text {
                    Layout.fillWidth: true
                    text: !root.wifiManager || !root.wifiManager.isPowered
                        ? "Off"
                        : (root.wifiManager.isConnected
                            ? "Connected to " + root.wifiManager.currentSsid + " · " + root.wifiManager.signalStrength + "%"
                            : "Not connected")
                    color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.82)
                    font.pixelSize: 10
                    font.family: "M PLUS 2"
                    elide: Text.ElideRight
                }
            }

            ConnectivityAction {
                visible: root.wifiManager && root.wifiManager.isConnected
                label: "Disconnect"
                theme: root.theme
                compact: true
                enabled: root.wifiManager && !root.wifiManager.isModifyingConnection
                onClicked: root.wifiManager.disconnectWifi()
            }

            Common.Switch {
                checked: root.wifiManager ? root.wifiManager.isPowered : false
                theme: root.theme
                enabled: root.wifiManager && !root.wifiManager.isTogglingPower
                onToggled: root.wifiManager.togglePower()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: -8
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: root.wifiManager && root.wifiManager.isRefreshing
                ? "Looking for nearby networks…"
                : "Nearby Networks"
            color: root.theme ? root.theme.textPrimary : "white"
            font.pixelSize: 12
            font.weight: Font.Medium
            font.family: "M PLUS 2"
        }
        Text {
            text: root.wifiManager ? String(root.wifiManager.availableNetworks.length) : "0"
            color: root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8)
            font.pixelSize: 10
            font.family: "M PLUS 2"
        }
        ConnectivityAction {
            label: root.wifiManager && root.wifiManager.isRefreshing ? "Scanning" : "Scan"
            theme: root.theme
            compact: true
            busy: root.wifiManager && root.wifiManager.isRefreshing
            enabled: root.wifiManager && root.wifiManager.isPowered && !root.wifiManager.isRefreshing
            onClicked: root.wifiManager.fullRefresh()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: nearbyBody.implicitHeight + 4
        radius: 15
        color: root.cardFill
        border.width: 1
        border.color: root.cardBorder

        ColumnLayout {
            id: nearbyBody
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 3
            spacing: 0

            ListView {
                id: networkList
                Layout.fillWidth: true
                Layout.preferredHeight: root.wifiManager && root.wifiManager.isPowered
                    ? Math.min(contentHeight, 245) : 0
                clip: true
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                model: root.wifiManager ? root.wifiManager.availableNetworks : []

                delegate: Item {
                    id: networkDelegate
                    required property var modelData
                    required property int index
                    property bool expanded: root.expandedNetworkIndex === index
                    readonly property var savedProfile: root.wifiManager
                        ? root.wifiManager.savedNetworks.find(profile => profile.ssid === modelData.ssid) : null
                    readonly property bool isSaved: !!savedProfile
                    readonly property bool connected: root.wifiManager.isConnected
                        && root.wifiManager.currentSsid === modelData.ssid
                    readonly property bool showsError: root.wifiManager.connectionError !== ""
                        && root.connectingNetworkIndex === index
                    width: networkList.width
                    implicitHeight: rowLayout.implicitHeight + (expanded ? passwordPanel.implicitHeight + 8 : 0) + 4
                    height: implicitHeight

                    ColumnLayout {
                        id: rowLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            Layout.leftMargin: 11
                            Layout.rightMargin: 10
                            spacing: 9

                            UI.SvgIcon {
                                Layout.preferredWidth: 17
                                Layout.preferredHeight: 17
                                source: connectivityIcons.wifiSvg
                                color: networkDelegate.connected
                                    ? (root.theme ? root.theme.accent : "white")
                                    : (root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.8))
                                opacity: networkDelegate.modelData.signal < 35 ? 0.6 : 0.95
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    Layout.fillWidth: true
                                    text: networkDelegate.modelData.ssid
                                    color: root.theme ? root.theme.textPrimary : "white"
                                    font.pixelSize: 11
                                    font.weight: networkDelegate.connected ? Font.Medium : Font.Normal
                                    font.family: "M PLUS 2"
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: (networkDelegate.isSaved ? "Saved" : (networkDelegate.modelData.secured ? "Secured" : "Open"))
                                        + " · " + networkDelegate.modelData.signal + "% signal"
                                    color: root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8)
                                    font.pixelSize: 9
                                    font.family: "M PLUS 2"
                                }
                            }

                            Text {
                                visible: networkDelegate.connected
                                text: "Connected"
                                color: root.theme ? root.theme.accent : Qt.rgba(0.4, 0.8, 0.55, 1)
                                font.pixelSize: 9
                                font.family: "M PLUS 2"
                            }

                            ConnectivityAction {
                                visible: !networkDelegate.connected
                                label: root.wifiManager.isConnecting && root.connectingNetworkIndex === networkDelegate.index
                                    ? "Connecting" : (networkDelegate.expanded && !networkDelegate.isSaved ? "Cancel" : "Connect")
                                theme: root.theme
                                compact: true
                                prominent: networkDelegate.expanded && !networkDelegate.isSaved
                                busy: root.wifiManager.isConnecting && root.connectingNetworkIndex === networkDelegate.index
                                enabled: !root.wifiManager.isConnecting
                                onClicked: {
                                    if (networkDelegate.expanded && !networkDelegate.isSaved) {
                                        root.expandedNetworkIndex = -1
                                    } else if (networkDelegate.isSaved) {
                                        root.connectingHint = networkDelegate.index
                                        root.connectingSsid = networkDelegate.modelData.ssid
                                        root.wifiManager.connectSavedNetwork(networkDelegate.savedProfile)
                                    } else if (networkDelegate.modelData.secured) {
                                        root.expandedNetworkIndex = networkDelegate.index
                                    } else {
                                        root.connectingHint = networkDelegate.index
                                        root.connectingSsid = networkDelegate.modelData.ssid
                                        root.wifiManager.connectToNetwork(networkDelegate.modelData.ssid, "")
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 11
                            Layout.rightMargin: 10
                            Layout.preferredHeight: 1
                            color: root.divider
                            visible: networkDelegate.index < networkList.count - 1 || networkDelegate.expanded
                        }
                    }

                    ColumnLayout {
                        id: passwordPanel
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: rowLayout.bottom
                        anchors.leftMargin: 11
                        anchors.rightMargin: 11
                        visible: networkDelegate.expanded && !networkDelegate.connected
                            && (!networkDelegate.isSaved || networkDelegate.showsError)
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 33
                            visible: !networkDelegate.isSaved
                            spacing: 8
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 9
                                color: root.theme ? Qt.rgba(root.theme.surfaceInsetCard.r, root.theme.surfaceInsetCard.g, root.theme.surfaceInsetCard.b, 0.55) : Qt.rgba(0, 0, 0, 0.16)
                                border.width: 1
                                border.color: passwordInput.activeFocus
                                    ? (root.theme ? root.theme.accent : Qt.rgba(0.4, 0.65, 1, 0.8))
                                    : root.cardBorder

                                TextInput {
                                    id: passwordInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: root.theme ? root.theme.textPrimary : "white"
                                    font.pixelSize: 10
                                    font.family: "M PLUS 2"
                                    echoMode: showPassword.checked ? TextInput.Normal : TextInput.Password
                                    selectByMouse: true
                                    selectionColor: root.theme ? root.theme.accent : Qt.rgba(0.4, 0.65, 1, 0.5)
                                    onTextChanged: root.bump()
                                    Keys.onReturnPressed: connectButton.clicked()

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Wi-Fi password"
                                        color: root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.65)
                                        font: passwordInput.font
                                        visible: passwordInput.text.length === 0
                                    }
                                }
                            }
                            ConnectivityAction {
                                id: showPassword
                                property bool checked: false
                                label: checked ? "Hide" : "Show"
                                theme: root.theme
                                compact: true
                                onClicked: checked = !checked
                            }
                            ConnectivityAction {
                                id: connectButton
                                label: root.wifiManager.isConnecting && root.connectingNetworkIndex === networkDelegate.index
                                    ? "Joining" : "Join"
                                theme: root.theme
                                compact: true
                                prominent: true
                                busy: root.wifiManager.isConnecting && root.connectingNetworkIndex === networkDelegate.index
                                enabled: passwordInput.text.length > 0 && !root.wifiManager.isConnecting
                                onClicked: {
                                    root.connectingHint = networkDelegate.index
                                    root.connectingSsid = networkDelegate.modelData.ssid
                                    root.wifiManager.connectToNetwork(networkDelegate.modelData.ssid, passwordInput.text)
                                    passwordInput.text = ""
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: networkDelegate.showsError
                            text: root.wifiManager.connectionError
                            color: root.theme ? root.theme.danger : Qt.rgba(0.95, 0.45, 0.55, 1)
                            font.pixelSize: 9
                            font.family: "M PLUS 2"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                visible: !root.wifiManager || !root.wifiManager.isPowered
                    || root.wifiManager.availableNetworks.length === 0
                spacing: 8
                UI.SvgIcon {
                    Layout.preferredWidth: 15
                    Layout.preferredHeight: 15
                    source: root.wifiManager && !root.wifiManager.isPowered
                        ? connectivityIcons.wifiOffSvg : connectivityIcons.wifiSvg
                    color: root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8)
                }
                Text {
                    Layout.fillWidth: true
                    text: !root.wifiManager || !root.wifiManager.isPowered
                        ? "Turn on Wi-Fi to see nearby networks"
                        : (root.wifiManager.isRefreshing ? "Searching for networks…" : "No networks found")
                    color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.8)
                    font.pixelSize: 10
                    font.family: "M PLUS 2"
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: "Known Networks"
            color: root.theme ? root.theme.textPrimary : "white"
            font.pixelSize: 12
            font.weight: Font.Medium
            font.family: "M PLUS 2"
        }
        Text {
            text: root.wifiManager ? String(root.wifiManager.savedNetworks.length) : "0"
            color: root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8)
            font.pixelSize: 10
            font.family: "M PLUS 2"
        }
        ConnectivityAction {
            label: root.savedNetworksExpanded ? "Hide" : "Show"
            theme: root.theme
            compact: true
            enabled: root.wifiManager && root.wifiManager.savedNetworks.length > 0
            onClicked: root.savedNetworksExpanded = !root.savedNetworksExpanded
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.savedNetworksExpanded
        implicitHeight: visible ? knownBody.implicitHeight + 4 : 0
        radius: 15
        color: root.cardFill
        border.width: 1
        border.color: root.cardBorder

        ColumnLayout {
            id: knownBody
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 3
            spacing: 0

            Repeater {
                model: root.wifiManager ? root.wifiManager.savedNetworks : []
                delegate: Item {
                    id: knownDelegate
                    required property var modelData
                    required property int index
                    readonly property bool connected: root.wifiManager.isConnected
                        && root.wifiManager.currentSsid === modelData.ssid
                    Layout.fillWidth: true
                    implicitHeight: 58

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 11
                        anchors.rightMargin: 10
                        spacing: 8

                        UI.SvgIcon {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            source: connectivityIcons.wifiSvg
                            color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.8)
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                Layout.fillWidth: true
                                text: modelData.ssid || modelData.name
                                color: root.theme ? root.theme.textPrimary : "white"
                                font.pixelSize: 10
                                font.family: "M PLUS 2"
                                elide: Text.ElideRight
                            }
                            Text {
                                text: knownDelegate.connected ? "Connected" : (modelData.autoConnect ? "Auto-join enabled" : "Auto-join off")
                                color: knownDelegate.connected
                                    ? (root.theme ? root.theme.accent : Qt.rgba(0.4, 0.8, 0.55, 1))
                                    : (root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8))
                                font.pixelSize: 9
                                font.family: "M PLUS 2"
                            }
                        }
                        ConnectivityAction {
                            label: knownDelegate.connected ? "Connected" : "Connect"
                            theme: root.theme
                            compact: true
                            enabled: root.wifiManager && root.wifiManager.isPowered
                                && !knownDelegate.connected && !root.wifiManager.isModifyingConnection
                            onClicked: {
                                root.connectingSsid = ""
                                root.connectingHint = -1
                                root.expandedNetworkIndex = -1
                                root.wifiManager.connectSavedNetwork(modelData)
                            }
                        }
                        ConnectivityAction {
                            label: modelData.autoConnect ? "Auto ✓" : "Auto"
                            theme: root.theme
                            compact: true
                            selected: modelData.autoConnect
                            enabled: root.wifiManager && !root.wifiManager.isModifyingConnection
                            onClicked: root.wifiManager.setNetworkAutoConnect(modelData, !modelData.autoConnect)
                        }
                        ConnectivityAction {
                            label: "Forget"
                            theme: root.theme
                            compact: true
                            destructive: true
                            enabled: root.wifiManager && !root.wifiManager.isModifyingConnection
                            onClicked: root.wifiManager.forgetNetwork(modelData)
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 11
                        anchors.rightMargin: 10
                        anchors.bottom: parent.bottom
                        height: 1
                        color: root.divider
                        visible: index < root.wifiManager.savedNetworks.length - 1
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                visible: !root.wifiManager || root.wifiManager.savedNetworks.length === 0
                text: "Saved networks will appear here."
                color: root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8)
                font.pixelSize: 10
                font.family: "M PLUS 2"
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.wifiManager && root.wifiManager.actionError !== ""
        text: root.wifiManager ? root.wifiManager.actionError : ""
        color: root.theme ? root.theme.danger : Qt.rgba(0.95, 0.45, 0.55, 1)
        font.pixelSize: 10
        font.family: "M PLUS 2"
        wrapMode: Text.WordWrap
    }

    Text {
        Layout.fillWidth: true
        text: "BLUETOOTH"
        color: root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8)
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1.2
        font.family: "M PLUS 2"
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: bluetoothHeader.implicitHeight + 20
        radius: 16
        color: root.cardFill
        border.width: 1
        border.color: root.cardBorder

        RowLayout {
            id: bluetoothHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 13
            spacing: 11

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 12
                color: root.theme ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.15) : Qt.rgba(0.25, 0.48, 0.95, 0.15)
                UI.SvgIcon {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    source: root.bluetoothManager && root.bluetoothManager.isPowered
                        ? connectivityIcons.bluetoothSvg : connectivityIcons.bluetoothSlashSvg
                    color: root.bluetoothManager && root.bluetoothManager.isPowered
                        ? (root.theme ? root.theme.accent : Qt.rgba(0.4, 0.65, 1, 1))
                        : (root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8))
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "Bluetooth"
                    color: root.theme ? root.theme.textPrimary : "white"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    font.family: "M PLUS 2"
                }
                Text {
                    Layout.fillWidth: true
                    text: !root.bluetoothManager || !root.bluetoothManager.isPowered
                        ? "Off"
                        : (root.bluetoothManager.hasConnectedDevices
                            ? root.bluetoothManager.pairedDevices.filter(device => device.connected).map(device => device.name || device.address).join(", ")
                            : "On · No connected devices")
                    color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.82)
                    font.pixelSize: 10
                    font.family: "M PLUS 2"
                    elide: Text.ElideRight
                }
            }

            ConnectivityAction {
                label: root.bluetoothManager && root.bluetoothManager.isScanning ? "Scanning" : "Scan"
                theme: root.theme
                compact: true
                busy: root.bluetoothManager && root.bluetoothManager.isScanning
                enabled: root.bluetoothManager && root.bluetoothManager.isPowered && !root.bluetoothManager.isScanning
                onClicked: root.bluetoothManager.startScan()
            }

            Common.Switch {
                checked: root.bluetoothManager ? root.bluetoothManager.isPowered : false
                theme: root.theme
                enabled: root.bluetoothManager && !root.bluetoothManager.isTogglingPower
                onToggled: root.bluetoothManager.togglePower()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: -8
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: "My Devices"
            color: root.theme ? root.theme.textPrimary : "white"
            font.pixelSize: 12
            font.weight: Font.Medium
            font.family: "M PLUS 2"
        }
        Text {
            text: root.bluetoothManager ? String(root.bluetoothManager.pairedDevices.length) : "0"
            color: root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8)
            font.pixelSize: 10
            font.family: "M PLUS 2"
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: pairedBody.implicitHeight + 4
        radius: 15
        color: root.cardFill
        border.width: 1
        border.color: root.cardBorder

        ColumnLayout {
            id: pairedBody
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 3
            spacing: 0

            Repeater {
                model: root.bluetoothManager && root.bluetoothManager.isPowered
                    ? root.bluetoothManager.pairedDevices : []
                delegate: Item {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 58

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 11
                        anchors.rightMargin: 10
                        spacing: 8

                        UI.SvgIcon {
                            Layout.preferredWidth: 17
                            Layout.preferredHeight: 17
                            source: modelData.connected ? connectivityIcons.bluetoothConnectedSvg : connectivityIcons.bluetoothSvg
                            color: modelData.connected
                                ? (root.theme ? root.theme.accent : Qt.rgba(0.4, 0.8, 0.55, 1))
                                : (root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.8))
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name || modelData.address
                                color: root.theme ? root.theme.textPrimary : "white"
                                font.pixelSize: 10
                                font.family: "M PLUS 2"
                                elide: Text.ElideRight
                            }
                            Text {
                                text: root.bluetoothManager.connectionAddress === modelData.address
                                    && root.bluetoothManager.connectionError !== ""
                                    ? root.bluetoothManager.connectionError
                                    : (modelData.connected ? "Connected" : "Paired")
                                color: root.bluetoothManager.connectionAddress === modelData.address
                                    && root.bluetoothManager.connectionError !== ""
                                    ? (root.theme ? root.theme.danger : Qt.rgba(0.95, 0.45, 0.55, 1))
                                    : (modelData.connected
                                        ? (root.theme ? root.theme.accent : Qt.rgba(0.4, 0.8, 0.55, 1))
                                        : (root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8)))
                                font.pixelSize: 9
                                font.family: "M PLUS 2"
                                elide: Text.ElideRight
                            }
                        }
                        ConnectivityAction {
                            label: modelData.connected ? "Disconnect" : "Connect"
                            theme: root.theme
                            compact: true
                            enabled: root.bluetoothManager
                                && (!root.bluetoothManager.isConnecting || modelData.connected)
                            onClicked: root.bluetoothManager.toggleDeviceConnection(
                                modelData.address, modelData.name || modelData.address, modelData.connected)
                        }
                        ConnectivityAction {
                            label: root.bluetoothManager.removingAddress === modelData.address
                                && root.bluetoothManager.isRemovingDevice ? "Removing" : "Forget"
                            theme: root.theme
                            compact: true
                            destructive: true
                            enabled: root.bluetoothManager && !root.bluetoothManager.isRemovingDevice
                            onClicked: root.bluetoothManager.forgetDevice(modelData.address)
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 11
                        anchors.rightMargin: 10
                        anchors.bottom: parent.bottom
                        height: 1
                        color: root.divider
                        visible: index < root.bluetoothManager.pairedDevices.length - 1
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                spacing: 8
                visible: !root.bluetoothManager || !root.bluetoothManager.isPowered
                    || root.bluetoothManager.pairedDevices.length === 0
                UI.SvgIcon {
                    Layout.preferredWidth: 15
                    Layout.preferredHeight: 15
                    source: root.bluetoothManager && root.bluetoothManager.isPowered
                        ? connectivityIcons.bluetoothSvg : connectivityIcons.bluetoothSlashSvg
                    color: root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8)
                }
                Text {
                    Layout.fillWidth: true
                    text: !root.bluetoothManager || !root.bluetoothManager.isPowered
                        ? "Turn on Bluetooth to manage devices"
                        : "Your paired devices will appear here"
                    color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.8)
                    font.pixelSize: 10
                    font.family: "M PLUS 2"
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: "Nearby Devices"
            color: root.theme ? root.theme.textPrimary : "white"
            font.pixelSize: 12
            font.weight: Font.Medium
            font.family: "M PLUS 2"
        }
        Text {
            visible: root.bluetoothManager && root.bluetoothManager.isScanning
            text: "Searching"
            color: root.theme ? root.theme.accent : Qt.rgba(0.4, 0.65, 1, 1)
            font.pixelSize: 9
            font.family: "M PLUS 2"
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: nearbyBluetoothBody.implicitHeight + 4
        radius: 15
        color: root.cardFill
        border.width: 1
        border.color: root.cardBorder

        ColumnLayout {
            id: nearbyBluetoothBody
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 3
            spacing: 0

            Repeater {
                model: root.bluetoothManager
                    ? root.bluetoothManager.availableDevices.filter(device => !device.paired) : []
                delegate: Item {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 58

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 11
                        anchors.rightMargin: 10
                        spacing: 8
                        UI.SvgIcon {
                            Layout.preferredWidth: 17
                            Layout.preferredHeight: 17
                            source: connectivityIcons.bluetoothSvg
                            color: root.theme ? root.theme.accent : Qt.rgba(0.4, 0.65, 1, 1)
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name || modelData.address
                                color: root.theme ? root.theme.textPrimary : "white"
                                font.pixelSize: 10
                                font.family: "M PLUS 2"
                                elide: Text.ElideRight
                            }
                            Text {
                                text: modelData.rssi < 0 ? "Nearby · " + modelData.rssi + " dBm" : "Nearby device"
                                color: root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8)
                                font.pixelSize: 9
                                font.family: "M PLUS 2"
                            }
                        }
                        Text {
                            visible: root.bluetoothManager.pairingAddress === modelData.address
                                && root.bluetoothManager.pairingError !== ""
                            text: root.bluetoothManager.pairingError
                            color: root.theme ? root.theme.danger : Qt.rgba(0.95, 0.45, 0.55, 1)
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                        ConnectivityAction {
                            label: root.bluetoothManager.isPairing && root.bluetoothManager.pairingAddress === modelData.address
                                ? "Pairing" : "Pair"
                            theme: root.theme
                            compact: true
                            prominent: true
                            busy: root.bluetoothManager.isPairing && root.bluetoothManager.pairingAddress === modelData.address
                            enabled: !root.bluetoothManager.isPairing
                            onClicked: {
                                root.pairingDeviceIndex = index
                                root.bluetoothManager.pairDevice(modelData.address, modelData.name || modelData.address)
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 11
                        anchors.rightMargin: 10
                        anchors.bottom: parent.bottom
                        height: 1
                        color: root.divider
                        visible: index < root.bluetoothManager.availableDevices.filter(device => !device.paired).length - 1
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                spacing: 8
                visible: !root.bluetoothManager || !root.bluetoothManager.isPowered
                    || root.bluetoothManager.availableDevices.filter(device => !device.paired).length === 0
                UI.SvgIcon {
                    Layout.preferredWidth: 15
                    Layout.preferredHeight: 15
                    source: root.bluetoothManager && root.bluetoothManager.isScanning
                        ? connectivityIcons.bluetoothSearchingSvg : connectivityIcons.bluetoothSvg
                    color: root.theme ? root.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.8)
                }
                Text {
                    Layout.fillWidth: true
                    text: !root.bluetoothManager || !root.bluetoothManager.isPowered
                        ? "Turn on Bluetooth to find nearby devices"
                        : (root.bluetoothManager.isScanning
                            ? "Searching for discoverable devices…"
                            : "Select Scan to find nearby devices")
                    color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.8)
                    font.pixelSize: 10
                    font.family: "M PLUS 2"
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.bluetoothManager && root.bluetoothManager.removeError !== ""
        text: root.bluetoothManager ? root.bluetoothManager.removeError : ""
        color: root.theme ? root.theme.danger : Qt.rgba(0.95, 0.45, 0.55, 1)
        font.pixelSize: 10
        font.family: "M PLUS 2"
        wrapMode: Text.WordWrap
    }

    Theme.IconProvider { id: connectivityIcons }
}
