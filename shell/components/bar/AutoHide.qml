import QtQuick

QtObject {
    id: root

    property bool enabled: false
    property bool held: false
    property bool stripHovered: false
    property bool barHovered: false
    property bool suspended: false

    readonly property int stripHeight: 2
    readonly property int revealDwell: 150
    readonly property int hideDelay: 650

    property bool revealed: false
    readonly property bool hidden: enabled && !held && !revealed
    readonly property bool dwellPending: root.dwellTimer.running
    readonly property bool hidePending: root.hideTimer.running

    function dwellElapsed() {
        if (stripHovered && !suspended) revealed = true
    }

    function hideDelayElapsed() {
        if (!stripHovered && !barHovered && !held) revealed = false
    }

    function update() {
        if (suspended) {
            root.dwellTimer.stop()
            root.hideTimer.stop()
            revealed = false
            return
        }
        if (held) {
            root.dwellTimer.stop()
            root.hideTimer.stop()
            revealed = true
            return
        }
        if (barHovered || (revealed && stripHovered)) {
            root.hideTimer.stop()
            return
        }
        if (stripHovered) {
            if (!root.dwellTimer.running) root.dwellTimer.start()
            return
        }
        root.dwellTimer.stop()
        if (revealed) root.hideTimer.restart()
    }

    onEnabledChanged: {
        root.dwellTimer.stop()
        root.hideTimer.stop()
        revealed = false
        if (enabled) update()
    }
    onHeldChanged: update()
    onStripHoveredChanged: update()
    onBarHoveredChanged: update()
    onSuspendedChanged: update()

    property Timer dwellTimer: Timer {
        interval: root.revealDwell
        onTriggered: root.dwellElapsed()
    }

    property Timer hideTimer: Timer {
        interval: root.hideDelay
        onTriggered: root.hideDelayElapsed()
    }
}
