import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    
    property string displayText: "--"
    
    property bool active: true

    property int consecutiveFailures: 0
    property bool queryAnswered: false
    property bool spawnFailed: false
    readonly property bool available: !spawnFailed && consecutiveFailures < 3

    property Timer pollTimer: Timer {
        interval: root.consecutiveFailures >= 3 ? 10000 : 1000
        repeat: true
        triggeredOnStart: true
        running: root.active
        onTriggered: {
            if (!queryProc.running) queryProc.running = true
        }
    }
    
    property Process initialQuery: Process {
        command: ["fcitx5-remote", "-n"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                let trimmed = data.trim()
                if (trimmed.length > 0) {
                    root.updateDisplayText(trimmed)
                }
            }
        }
    }
    
    property Process queryProcess: Process {
        id: queryProc
        command: ["fcitx5-remote", "-n"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                let trimmed = data.trim()
                if (trimmed.length > 0) {
                    root.queryAnswered = true
                    root.updateDisplayText(trimmed)
                }
            }
        }

        property bool spawned: false

        onStarted: spawned = true

        // A binary that cannot be spawned never emits started or exited, so the outcome is judged when running drops.
        onRunningChanged: {
            if (running) return
            root.spawnFailed = !spawned
            spawned = false
            root.consecutiveFailures = root.queryAnswered ? 0 : root.consecutiveFailures + 1
            root.queryAnswered = false
        }
    }
    
    function updateDisplayText(imName) {
        let newText = "--"
        
        if (!imName || imName === "") {
            newText = "--"
        } else if (imName.includes("mozc") || imName.includes("Mozc")) {
            newText = "あ"
        } else if (imName.includes("keyboard-jp") || imName.includes("jp")) {
            newText = "JP"
        } else if (imName.includes("keyboard-us") || imName.includes("us")) {
            newText = "US"
        } else {
            newText = imName.substring(0, 2).toUpperCase()
        }
        
        if (newText !== root.displayText) {
            root.displayText = newText
        }
    }
    
    property Timer initTimer: Timer {
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            root.initialQuery.running = true
        }
    }
    
    Component.onCompleted: {
        // Delay initial query to wait for fcitx5 to start
        initTimer.start()
    }
}
