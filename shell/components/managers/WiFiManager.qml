import QtQuick
import Quickshell.Io

QtObject {
    id: wifiManager

    property bool isPowered: true
    property bool isConnected: false
    property string currentSsid: "Not Connected"
    property int signalStrength: 0
    property var availableNetworks: []
    property var savedNetworks: []

    property bool isConnecting: false
    property string connectionError: ""
    property string actionError: ""
    property string actionNetwork: ""
    property bool isRefreshing: false
    property bool hasRefreshed: false

    readonly property bool isTogglingPower: wifiToggleProcess.running
    readonly property bool isModifyingConnection: disconnectProcess.running || savedNetworkProcess.running || forgetNetworkProcess.running || autoConnectProcess.running

    function togglePower() {
        wifiToggleProcess.running = true
    }

    function refreshWifiStatus() {
        wifiStatusProcess.running = true
        wifiPowerStatusProcess.running = true
    }

    function scanNetworks() {
        wifiScanProcess.running = true
    }

    function refreshSavedNetworks() {
        savedNetworksProcess.outputData = ""
        savedNetworksProcess.running = true
    }

    function disconnectWifi() {
        actionError = ""
        actionNetwork = currentSsid
        disconnectProcess.running = true
    }

    // Profiles are addressed by UUID: names repeat ("Home 1") and need not match the SSID.
    function connectSavedNetwork(profile) {
        actionError = ""
        actionNetwork = profile.ssid || profile.name
        connectionError = ""
        isConnecting = true
        savedNetworkProcess.command = ["nmcli", "connection", "up", "uuid", profile.uuid]
        savedNetworkProcess.running = true
    }

    function forgetNetwork(profile) {
        actionError = ""
        actionNetwork = profile.ssid || profile.name
        forgetNetworkProcess.command = ["nmcli", "connection", "delete", "uuid", profile.uuid]
        forgetNetworkProcess.running = true
    }

    function setNetworkAutoConnect(profile, enabled) {
        actionError = ""
        actionNetwork = profile.ssid || profile.name
        autoConnectProcess.command = ["nmcli", "connection", "modify", "uuid", profile.uuid,
                                      "connection.autoconnect", enabled ? "yes" : "no"]
        autoConnectProcess.running = true
    }

    function connectToNetwork(ssid, password) {
        isConnecting = true
        connectionError = ""

        // /proc/<pid>/cmdline is world-readable and environ is not, so the key travels in the
        // environment and only ever reaches nmcli via passwd-file, never as one of its own args.
        if (password.length > 0) {
            connectToNetworkProcess.environment = ({ "MUGEN_WIFI_PSK": password })
            connectToNetworkProcess.command = [
                "bash", "-c",
                "export LANG=C; set -e; tmp=$(mktemp); trap 'rm -f \"$tmp\"' EXIT; " +
                "printf '802-11-wireless-security.psk:%s\\n' \"$MUGEN_WIFI_PSK\" > \"$tmp\"; " +
                // Reuse an existing profile so its custom settings (e.g. a static IP) survive.
                "nmcli connection show \"$1\" >/dev/null 2>&1 || " +
                "nmcli connection add type wifi con-name \"$1\" ssid \"$1\" -- wifi-sec.key-mgmt wpa-psk >/dev/null; " +
                "nmcli connection up \"$1\" passwd-file \"$tmp\"",
                "bash", ssid
            ]
        } else {
            connectToNetworkProcess.environment = ({})
            connectToNetworkProcess.command = [
                "bash", "-c",
                "LANG=C nmcli dev wifi connect \"$1\"",
                "bash", ssid
            ]
        }

        connectToNetworkProcess.running = true
    }

    // nmcli -t escapes a literal ':' as '\:', so a plain split(":") would over-split an SSID.
    function splitNmcli(line) {
        let fields = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            let c = line[i]
            if (c === "\\" && i + 1 < line.length) {
                cur += line[i + 1]
                i++
            } else if (c === ":") {
                fields.push(cur)
                cur = ""
            } else {
                cur += c
            }
        }
        fields.push(cur)
        return fields
    }

    function fullRefresh() {
        hasRefreshed = true
        isRefreshing = true
        refreshWifiStatus()
        scanNetworks()
        refreshSavedNetworks()
    }

    // The list view of `connection show` rejects setting fields such as 802-11-wireless.ssid.
    property Process savedNetworksProcess: Process {
        command: ["bash", "-c",
            "export LANG=C; nmcli -t -f UUID,TYPE connection show | " +
            "awk -F: '$2 == \"802-11-wireless\" { print \"uuid\"; print $1 }' | " +
            "xargs -r -d '\\n' nmcli -t -e no -f connection.uuid,connection.id,connection.autoconnect,802-11-wireless.ssid connection show"]
        running: false
        property string outputData: ""

        stdout: SplitParser {
            onRead: data => { savedNetworksProcess.outputData += data + "\n" }
        }

        onExited: (code, status) => {
            let networks = []
            let profile = null
            if (code === 0) {
                for (const line of savedNetworksProcess.outputData.split("\n")) {
                    const sep = line.indexOf(":")
                    if (sep < 0) continue
                    const key = line.slice(0, sep)
                    const value = line.slice(sep + 1)
                    if (key === "connection.uuid") {
                        profile = { uuid: value, name: "", ssid: "", autoConnect: false }
                        networks.push(profile)
                    } else if (!profile) {
                        continue
                    } else if (key === "connection.id") {
                        profile.name = value
                    } else if (key === "connection.autoconnect") {
                        profile.autoConnect = value === "yes"
                    } else if (key === "802-11-wireless.ssid") {
                        profile.ssid = value
                    }
                }
            }
            wifiManager.savedNetworks = networks
            savedNetworksProcess.outputData = ""
        }
    }

    // `connection down` leaves the device free to autoconnect straight to another saved network.
    property Process disconnectProcess: Process {
        command: ["bash", "-c",
            "LANG=C nmcli -t -f DEVICE,TYPE,STATE device | " +
            "awk -F: '$2 == \"wifi\" && $3 ~ /^connected/ { print $1 }' | " +
            "xargs -r -n1 nmcli device disconnect"]
        running: false
        property string errorData: ""
        stderr: SplitParser { onRead: data => { disconnectProcess.errorData += data } }
        onExited: (code, status) => {
            wifiManager.actionError = code === 0 ? "" : "Could not disconnect from " + wifiManager.actionNetwork
            wifiManager.refreshWifiStatus()
            disconnectProcess.errorData = ""
        }
    }

    property Process savedNetworkProcess: Process {
        running: false
        property string errorData: ""
        stderr: SplitParser { onRead: data => { savedNetworkProcess.errorData += data } }
        onExited: (code, status) => {
            wifiManager.actionError = code === 0 ? "" : "Could not connect to " + wifiManager.actionNetwork
            wifiManager.connectionError = code === 0 ? "" : "Could not connect to " + wifiManager.actionNetwork
            wifiManager.isConnecting = false
            wifiManager.refreshWifiStatus()
            wifiManager.refreshSavedNetworks()
            savedNetworkProcess.errorData = ""
        }
    }

    property Process forgetNetworkProcess: Process {
        running: false
        property string errorData: ""
        stderr: SplitParser { onRead: data => { forgetNetworkProcess.errorData += data } }
        onExited: (code, status) => {
            wifiManager.actionError = code === 0 ? "" : "Could not forget " + wifiManager.actionNetwork
            wifiManager.refreshSavedNetworks()
            forgetNetworkProcess.errorData = ""
        }
    }

    property Process autoConnectProcess: Process {
        running: false
        property string errorData: ""
        stderr: SplitParser { onRead: data => { autoConnectProcess.errorData += data } }
        onExited: (code, status) => {
            wifiManager.actionError = code === 0 ? "" : "Could not update auto-connect for " + wifiManager.actionNetwork
            wifiManager.refreshSavedNetworks()
            autoConnectProcess.errorData = ""
        }
    }

    property Process wifiStatusProcess: Process {
        command: ["bash", "-c", "LANG=C nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi list --rescan no | grep '^yes'"]
        running: false

        property string outputData: ""

        stdout: SplitParser {
            onRead: data => {
                wifiStatusProcess.outputData += data
            }
        }

        onExited: (code, status) => {
            let trimmed = wifiStatusProcess.outputData.trim()

            if (code === 0 && trimmed.length > 0) {
                let parts = wifiManager.splitNmcli(trimmed)

                if (parts.length >= 3 && parts[0] === "yes") {
                    wifiManager.isConnected = true
                    wifiManager.currentSsid = parts[1]
                    wifiManager.signalStrength = parseInt(parts[2]) || 0
                } else {
                    wifiManager.isConnected = false
                    wifiManager.currentSsid = "Not Connected"
                    wifiManager.signalStrength = 0
                }
            } else {
                wifiManager.isConnected = false
                wifiManager.currentSsid = "Not Connected"
                wifiManager.signalStrength = 0
            }

            wifiStatusProcess.outputData = ""
            checkRefreshComplete()
        }

        function checkRefreshComplete() {
            if (!wifiScanProcess.running) {
                wifiManager.isRefreshing = false
            }
        }
    }

    property Process wifiScanProcess: Process {
        command: ["bash", "-c", "LANG=C nmcli -t -f SSID,SIGNAL,SECURITY dev wifi"]
        running: false

        property var networks: []

        stdout: SplitParser {
            onRead: data => {
                let trimmed = data.trim()
                if (trimmed.length > 0) {
                    let parts = wifiManager.splitNmcli(trimmed)
                    if (parts.length >= 3) {
                        let ssid = parts[0]
                        let signal = parseInt(parts[1]) || 0
                        let secured = parts[2].length > 0

                        if (ssid.length > 0) {
                            wifiScanProcess.networks.push({
                                "ssid": ssid,
                                "signal": signal,
                                "secured": secured
                            })
                        }
                    }
                }
            }
        }

        onExited: (code, status) => {
            let sortedNetworks = wifiScanProcess.networks.sort((a, b) => b.signal - a.signal)
            wifiScanProcess.networks = []

            if (!wifiStatusProcess.running) {
                wifiManager.isRefreshing = false
                wifiManager.availableNetworks = sortedNetworks
            } else {
                wifiManager.availableNetworks = sortedNetworks
            }
        }
    }

    property Process connectToNetworkProcess: Process {
        running: false

        property string outputData: ""
        property string errorData: ""

        stdout: SplitParser {
            onRead: data => {
                connectToNetworkProcess.outputData += data
            }
        }

        stderr: SplitParser {
            onRead: data => {
                connectToNetworkProcess.errorData += data
            }
        }

        onExited: (code, status) => {
            if (code === 0) {
                wifiManager.connectionError = ""
                wifiManager.refreshWifiStatus()
                wifiManager.refreshSavedNetworks()
            } else {
                let errorMsg = connectToNetworkProcess.errorData.toLowerCase()

                if (errorMsg.includes("secret") || errorMsg.includes("password") || errorMsg.includes("psk")) {
                    wifiManager.connectionError = "Incorrect password"
                } else if (errorMsg.includes("timeout") || errorMsg.includes("no reply")) {
                    wifiManager.connectionError = "Connection timeout"
                } else if (errorMsg.includes("not found")) {
                    wifiManager.connectionError = "Network not found"
                } else {
                    wifiManager.connectionError = "Connection failed"
                }
            }

            wifiManager.isConnecting = false
            connectToNetworkProcess.outputData = ""
            connectToNetworkProcess.errorData = ""
        }
    }

    property Process wifiPowerStatusProcess: Process {
        command: ["bash", "-c", "nmcli radio wifi | grep -q 'enabled' && echo 'yes' || echo 'no'"]
        running: false

        property string outputData: ""

        stdout: SplitParser {
            onRead: data => {
                wifiPowerStatusProcess.outputData += data
            }
        }

        onExited: (code, status) => {
            let trimmed = wifiPowerStatusProcess.outputData.trim().toLowerCase()
            let wasPowered = wifiManager.isPowered
            wifiManager.isPowered = (trimmed === "yes")
            wifiPowerStatusProcess.outputData = ""

            if (!wifiManager.isPowered) {
                wifiManager.availableNetworks = []
                wifiManager.isConnected = false
                wifiManager.currentSsid = "Not Connected"
                wifiManager.signalStrength = 0
            } else if (!wasPowered) {
                Qt.callLater(() => {
                    fullRefresh()
                })
            }
        }
    }

    property Process wifiToggleProcess: Process {
        command: ["bash", "-c", wifiManager.isPowered ? "nmcli radio wifi off" : "nmcli radio wifi on"]
        running: false

        onExited: (code, status) => {
            wifiPowerStatusProcess.running = true
        }
    }

    property Process dbusMonitor: Process {
        command: [
            "dbus-monitor",
            "--system",
            "type='signal',sender='org.freedesktop.NetworkManager'"
        ]
        running: !wifiManager.monitorRestartTimer.running

        stdout: SplitParser {
            onRead: data => {
                wifiDebounceTimer.restart()
            }
        }

        // The stream ends when the process does, so this is where a dead monitor shows up.
        stderr: StdioCollector {
            onStreamFinished: wifiManager.monitorRestartTimer.restart()
        }
    }

    // A bus hiccup would otherwise leave the Wi-Fi state frozen until the panel is reopened.
    property Timer monitorRestartTimer: Timer {
        interval: 2000
    }

    property Timer wifiDebounceTimer: Timer {
        interval: 200
        repeat: false
        onTriggered: {
            if (!wifiStatusProcess.running && !wifiPowerStatusProcess.running) {
                refreshWifiStatus()
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            refreshWifiStatus()
        })
    }

    Component.onDestruction: {
        if (dbusMonitor.running) {
            dbusMonitor.running = false
        }
    }
}
