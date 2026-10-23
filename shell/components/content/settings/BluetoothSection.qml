pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../common" as Common
import "../../../lib" as Theme

Rectangle {
    id: section

    required property var theme
    required property var modeManager
    required property var bluetoothManager

    readonly property color danger: theme ? theme.danger : Qt.rgba(0.95, 0.45, 0.55, 1)
    readonly property bool powered: bluetoothManager ? bluetoothManager.isPowered : false
    readonly property var paired: bluetoothManager
        ? bluetoothManager.pairedDevices.slice().sort((a, b) => (!!b.connected) - (!!a.connected)) : []
    readonly property var nearby: bluetoothManager
        ? bluetoothManager.availableDevices.filter(d => !d.paired) : []
    readonly property string status: {
        if (!powered) return "Off"
        const names = paired.filter(d => d.connected).map(d => d.name || d.address)
        return names.length > 0 ? "Connected to " + names.join(", ") : "On"
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

    Component.onCompleted: {
        if (bluetoothManager) bluetoothManager.refreshStatus()
    }

    Theme.IconProvider { id: icons }

    Component {
        id: pairedRow

        ConnectivityRow {
            id: row

            required property var modelData

            property bool armed: false
            readonly property bool failed: section.bluetoothManager.connectionAddress === modelData.address
                && section.bluetoothManager.connectionError !== ""
            readonly property bool connectingThis: section.bluetoothManager.isConnecting
                && section.bluetoothManager.pendingConnectAddress === modelData.address
            readonly property bool removingThis: section.bluetoothManager.isRemovingDevice
                && section.bluetoothManager.removingAddress === modelData.address

            width: ListView.view.width
            theme: section.theme
            icon: modelData.connected ? icons.bluetoothConnectedSvg : icons.bluetoothSvg
            active: !!modelData.connected
            hasError: failed
            title: modelData.name || modelData.address
            detail: failed ? section.bluetoothManager.connectionError
                : modelData.connected ? "Connected" : "Paired"

            Timer {
                id: disarmTimer
                interval: 5000
                onTriggered: row.armed = false
            }

            Common.ActionButton {
                theme: section.theme
                buttonWidth: 104
                label: row.connectingThis
                    ? (section.bluetoothManager.pendingDisconnect ? "Disconnecting…" : "Connecting…")
                    : row.modelData.connected ? "Disconnect" : "Connect"
                enabled: !section.bluetoothManager.isConnecting || !!row.modelData.connected
                opacity: enabled ? 1 : 0.45
                onClicked: {
                    section.bluetoothManager.toggleDeviceConnection(
                        row.modelData.address, row.modelData.name || row.modelData.address, row.modelData.connected)
                    section.bump()
                }
            }

            Common.ActionButton {
                theme: section.theme
                buttonWidth: 80
                label: row.removingThis ? "Removing…" : row.armed ? "Confirm" : "Forget"
                tint: Qt.rgba(section.danger.r, section.danger.g, section.danger.b, row.armed ? 0.34 : 0.16)
                tintHover: Qt.rgba(section.danger.r, section.danger.g, section.danger.b, row.armed ? 0.46 : 0.28)
                enabled: !section.bluetoothManager.isRemovingDevice
                opacity: enabled ? 1 : 0.45
                onClicked: {
                    if (!row.armed) {
                        row.armed = true
                        disarmTimer.restart()
                    } else {
                        row.armed = false
                        disarmTimer.stop()
                        section.bluetoothManager.forgetDevice(row.modelData.address)
                    }
                    section.bump()
                }
            }
        }
    }

    Component {
        id: nearbyRow

        ConnectivityRow {
            id: row

            required property var modelData

            readonly property bool failed: section.bluetoothManager.pairingAddress === modelData.address
                && section.bluetoothManager.pairingError !== ""
            readonly property bool pairingThis: section.bluetoothManager.isPairing
                && section.bluetoothManager.pairingAddress === modelData.address

            width: ListView.view.width
            theme: section.theme
            icon: icons.bluetoothSvg
            hasError: failed
            title: modelData.name || modelData.address
            detail: failed ? section.bluetoothManager.pairingError
                : modelData.rssi < 0 ? "Signal " + modelData.rssi + " dBm" : "Nearby"

            Common.ActionButton {
                theme: section.theme
                buttonWidth: 84
                label: row.pairingThis ? "Pairing…" : "Pair"
                enabled: !section.bluetoothManager.isPairing
                opacity: enabled ? 1 : 0.45
                onClicked: {
                    section.bluetoothManager.pairDevice(row.modelData.address, row.modelData.name || row.modelData.address)
                    section.bump()
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
                title: "Bluetooth"
                desc: section.status
            }

            Common.Switch {
                theme: section.theme
                checked: section.powered
                enabled: section.bluetoothManager ? !section.bluetoothManager.isTogglingPower : false
                onToggled: {
                    if (section.bluetoothManager) section.bluetoothManager.togglePower()
                    section.bump()
                }
            }
        }

        Common.SectionTitle {
            Layout.leftMargin: 2
            visible: section.powered
            theme: section.theme
            text: "My devices"
        }

        ConnectivityList {
            Layout.fillWidth: true
            visible: section.powered
            theme: section.theme
            model: section.paired
            rowDelegate: pairedRow
            placeholder: "No paired devices"
        }

        Common.SectionTitle {
            Layout.leftMargin: 2
            Layout.topMargin: 4
            visible: section.powered
            theme: section.theme
            text: "Nearby"
        }

        ConnectivityList {
            Layout.fillWidth: true
            visible: section.powered
            theme: section.theme
            model: section.nearby
            rowDelegate: nearbyRow
            placeholder: section.bluetoothManager && section.bluetoothManager.isScanning
                ? "Searching for devices…" : "Scan to find devices"
        }

        RowLayout {
            Layout.fillWidth: true
            visible: section.powered
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Put a device in pairing mode, then scan."
                color: section.theme ? section.theme.textFaint : Qt.rgba(0.62, 0.62, 0.72, 0.60)
                font.pixelSize: 10
                font.family: "M PLUS 2"
                font.letterSpacing: 0.3
                wrapMode: Text.WordWrap
            }

            Common.ActionButton {
                theme: section.theme
                buttonWidth: 84
                label: section.bluetoothManager && section.bluetoothManager.isScanning ? "Scanning…" : "Scan"
                enabled: section.bluetoothManager ? !section.bluetoothManager.isScanning : false
                opacity: enabled ? 1 : 0.45
                onClicked: {
                    section.bluetoothManager.startScan()
                    section.bump()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: section.powered && text !== ""
            text: section.bluetoothManager ? section.bluetoothManager.removeError : ""
            color: section.danger
            font.pixelSize: 10
            font.family: "M PLUS 2"
            wrapMode: Text.WordWrap
        }
    }
}
