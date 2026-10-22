import QtQuick
import "../common" as Common
import "../ui" as UI
import "../../lib" as Theme

Item {
    id: button

    required property var modeManager

    property string icon: ""
    property string iconSource: ""
    property color backgroundColor: Qt.rgba(0.55, 0.45, 0.75, 1.0)
    property color iconBaseColor: Qt.rgba(1, 1, 1, 0.65)
    property color iconHoverColor: Qt.rgba(1, 1, 1, 0.98)
    property real hoverScale: 1.12
    property real iconRatio: 0.42

    signal clicked()

    implicitWidth: modeManager.scale(60)
    implicitHeight: modeManager.scale(60)

    readonly property real baseLength: Math.max(width, height)
    readonly property real iconSize: baseLength * iconRatio
    readonly property real effectSize: baseLength + modeManager.scale(18)

    Item {
        id: glowLayer
        anchors.centerIn: parent
        width: button.effectSize
        height: button.effectSize
        z: -1

        opacity: mouseArea.containsMouse ? 1.0 : 0.85

        Behavior on opacity {
            NumberAnimation { duration: Theme.Motion.gentle; easing.type: Easing.OutCubic }
        }

        property real heartbeat: 1.0

        SequentialAnimation on heartbeat {
            id: heartbeatAnimation
            loops: Animation.Infinite
            running: mouseArea.containsMouse
            paused: heartbeatAnimation.running && !Theme.Motion.ambient
            onRunningChanged: if (running) heartbeatSettle.stop(); else heartbeatSettle.start()
            NumberAnimation { to: 1.14; duration: 420; easing.type: Easing.OutCubic }
            NumberAnimation { to: 1.0; duration: 420; easing.type: Easing.InCubic }
            PauseAnimation { duration: 200 }
            NumberAnimation { to: 1.12; duration: 360; easing.type: Easing.OutCubic }
            NumberAnimation { to: 1.0; duration: 360; easing.type: Easing.InCubic }
            PauseAnimation { duration: 720 }
        }

        NumberAnimation {
            id: heartbeatSettle
            target: glowLayer
            property: "heartbeat"
            to: 1.0
            duration: Theme.Motion.fast
            easing.type: Easing.OutCubic
        }

        Common.BlobEffect {
            anchors.fill: parent
            blobColor: button.backgroundColor
            layers: 3
            waveAmplitude: 4.0
            baseOpacity: 0.8
            animationSpeed: 0.05
            pointCount: 16
            running: true
            scale: Theme.Motion.reduced ? 1.0 : glowLayer.heartbeat
        }
    }

    property real floatX: 0
    property real floatY: 0

    property real offsetX: (Math.random() - 0.5) * 2
    property real offsetY: (Math.random() - 0.5) * 2
    property real animDuration: 1200 + Math.random() * 800
    property real animDelay: Math.random() * 1600

    SequentialAnimation on floatX {
        id: floatXAnimation
        loops: Animation.Infinite
        running: true
        paused: floatXAnimation.running && !Theme.Motion.ambient
        PauseAnimation { duration: button.animDelay }
        NumberAnimation { to: button.offsetX * 8; duration: button.animDuration; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: button.animDuration; easing.type: Easing.InOutSine }
        NumberAnimation { to: -button.offsetX * 8; duration: button.animDuration; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: button.animDuration; easing.type: Easing.InOutSine }
    }

    SequentialAnimation on floatY {
        id: floatYAnimation
        loops: Animation.Infinite
        running: true
        paused: floatYAnimation.running && !Theme.Motion.ambient
        PauseAnimation { duration: button.animDelay }
        NumberAnimation { to: button.offsetY * 8; duration: button.animDuration; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: button.animDuration; easing.type: Easing.InOutSine }
        NumberAnimation { to: -button.offsetY * 8; duration: button.animDuration; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: button.animDuration; easing.type: Easing.InOutSine }
    }

    transform: Translate {
        x: Theme.Motion.reduced ? 0 : button.floatX
        y: Theme.Motion.reduced ? 0 : button.floatY
    }

    UI.SvgIcon {
        id: iconSvg
        anchors.centerIn: parent
        width: button.iconSize
        height: button.iconSize
        source: button.iconSource
        color: mouseArea.containsMouse ? button.iconHoverColor : button.iconBaseColor
        visible: button.iconSource !== ""
        scale: mouseArea.containsMouse ? button.hoverScale : 1.0

        Behavior on scale { NumberAnimation { duration: Theme.Motion.slow; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.Motion.standard; easing.type: Easing.OutCubic } }
    }

    Text {
        anchors.centerIn: parent
        text: button.icon
        font.pixelSize: button.iconSize
        color: mouseArea.containsMouse ? button.iconHoverColor : button.iconBaseColor
        visible: button.iconSource === "" && button.icon !== ""
        scale: mouseArea.containsMouse ? button.hoverScale : 1.0

        Behavior on scale { NumberAnimation { duration: Theme.Motion.slow; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.Motion.standard; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}

