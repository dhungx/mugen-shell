import QtQuick
import Quickshell
import Quickshell.Io
import "../../lib" as Theme

QtObject {
    id: playback

    property var settingsManager
    property var toplevels: []
    property string videoPath: ""
    property string socketPath: Theme.Paths.cacheDir + "/wallp/mpvpaper.sock"

    readonly property bool wantPause: Theme.WallpaperRules.wantPause(
        toplevels,
        settingsManager ? settingsManager.wallpaperPauseWhen : "fullscreen",
        settingsManager ? settingsManager.wallpaperPauseApps : [])

    property bool ready: false
    property bool holding: false
    property bool mpvPaused: false
    property bool observing: false
    property bool markerKnown: false
    property bool pausePending: false

    property int retryDelay: 0
    readonly property int retryDelayBase: 500
    readonly property int retryDelayMax: 30000

    // The binding's first evaluation emits this before the real windows have arrived.
    onToplevelsChanged: {
        if (settleTimer.running) Qt.callLater(() => playback.ready = true)
    }

    onReadyChanged: decide()
    onWantPauseChanged: decide()

    onVideoPathChanged: {
        if (videoPath === "") {
            retryTimer.stop()
            socket.connected = false
            holding = false
            mpvPaused = false
            observing = false
            markerKnown = false
            pausePending = false
            return
        }
        retryDelay = 0
        retryTimer.stop()
        reconnect()
    }

    Component.onCompleted: {
        settleTimer.start()
        reconnect()
    }

    function reconnect() {
        if (videoPath === "" || socket.connected) return
        socket.connected = true
        if (!socket.connected) scheduleRetry()
    }

    function scheduleRetry() {
        if (retryTimer.running) return
        retryDelay = retryDelay === 0 ? retryDelayBase : Math.min(retryDelay * 2, retryDelayMax)
        retryTimer.interval = retryDelay
        retryTimer.start()
    }

    function handleLine(line) {
        let msg
        try {
            msg = JSON.parse(line)
        } catch (e) {
            return
        }
        if (msg === null || typeof msg !== "object") return
        if (msg.event === "property-change" && msg.id === 1) {
            pausePending = false
            mpvPaused = msg.data === true
            observing = true
            decide()
        } else if (msg.request_id === 2) {
            holding = msg.error === "success" && msg.data === true
            markerKnown = true
            decide()
        }
    }

    function decide() {
        if (!socket.connected || !observing || !markerKnown || !ready || pausePending) return
        const action = Theme.WallpaperRules.pauseAction(wantPause, mpvPaused, holding)
        if (action === "pause") {
            holding = true
            pausePending = true
            send(["set_property", "user-data/mugen-shell/paused", true])
            send(["set_property", "pause", true])
        } else if (action === "resume") {
            holding = false
            send(["set_property", "pause", false])
            send(["del", "user-data/mugen-shell/paused"])
        } else if (action === "release") {
            holding = false
            send(["del", "user-data/mugen-shell/paused"])
        }
    }

    function applyProperties() {
        if (!socket.connected || !settingsManager) return
        const s = settingsManager
        const properties = Theme.WallpaperRules.mpvProperties({
            speed: s.wallpaperSpeed,
            sound: s.wallpaperSound,
            volume: s.wallpaperVolume,
            fit: s.wallpaperFit,
            brightness: s.wallpaperBrightness,
            saturation: s.wallpaperSaturation
        })
        for (const [name, value] of properties)
            send(["set_property", name, value])
    }

    function send(command, requestId) {
        socket.write(JSON.stringify(requestId ? { command: command, request_id: requestId } : { command: command }) + "\n")
        socket.flush()
    }

    property Socket socket: Socket {
        path: playback.socketPath
        parser: SplitParser {
            onRead: line => playback.handleLine(line)
        }
        onConnectedChanged: {
            if (connected) {
                playback.retryDelay = 0
                playback.retryTimer.stop()
                playback.observing = false
                playback.markerKnown = false
                playback.holding = false
                playback.pausePending = false
                playback.send(["observe_property", 1, "pause"], 1)
                playback.send(["get_property", "user-data/mugen-shell/paused"], 2)
                playback.applyProperties()
            } else {
                playback.observing = false
                playback.markerKnown = false
                playback.pausePending = false
                if (playback.videoPath !== "") playback.scheduleRetry()
            }
        }
    }

    property Timer retryTimer: Timer {
        repeat: false
        onTriggered: playback.reconnect()
    }

    property Timer settleTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: playback.ready = true
    }

    property Connections settingsWatch: Connections {
        target: playback.settingsManager || null
        function onWallpaperSpeedChanged() { playback.applyProperties() }
        function onWallpaperSoundChanged() { playback.applyProperties() }
        function onWallpaperVolumeChanged() { playback.applyProperties() }
        function onWallpaperFitChanged() { playback.applyProperties() }
        function onWallpaperBrightnessChanged() { playback.applyProperties() }
        function onWallpaperSaturationChanged() { playback.applyProperties() }
    }
}
