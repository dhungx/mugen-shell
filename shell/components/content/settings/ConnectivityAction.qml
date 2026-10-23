import QtQuick
import "../../../lib" as Theme

Rectangle {
    id: action

    property string label: ""
    property var theme
    property bool prominent: false
    property bool destructive: false
    property bool selected: false
    property bool compact: false
    property bool busy: false
    signal clicked()

    implicitWidth: actionLabel.implicitWidth + (compact ? 18 : 24)
    width: implicitWidth
    height: compact ? 28 : 32
    radius: height / 2
    color: {
        if (!enabled) return Qt.rgba(0.5, 0.5, 0.5, 0.08)
        if (prominent) return theme ? theme.accent : Qt.rgba(0.25, 0.48, 0.95, 1)
        if (destructive) return Qt.rgba(0.86, 0.25, 0.34, mouseArea.containsMouse ? 0.16 : 0.08)
        if (selected) return theme
            ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, mouseArea.containsMouse ? 0.22 : 0.14)
            : Qt.rgba(0.25, 0.48, 0.95, mouseArea.containsMouse ? 0.22 : 0.14)
        return mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    }
    border.width: prominent || destructive ? 0 : 1
    border.color: theme ? Qt.rgba(theme.surfaceBorder.r, theme.surfaceBorder.g, theme.surfaceBorder.b, mouseArea.containsMouse ? 0.9 : 0.65)
                       : Qt.rgba(1, 1, 1, 0.18)
    opacity: enabled ? 1 : 0.52

    Behavior on color { ColorAnimation { duration: Theme.Motion.micro; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: Theme.Motion.micro; easing.type: Easing.OutCubic } }

    Text {
        id: actionLabel
        anchors.centerIn: parent
        text: action.busy ? action.label + "…" : action.label
        color: action.destructive
            ? (action.theme ? action.theme.danger : Qt.rgba(0.95, 0.45, 0.55, 1))
            : (action.theme ? action.theme.textPrimary : "white")
        font.pixelSize: action.compact ? 10 : 11
        font.weight: action.prominent || action.selected ? Font.Medium : Font.Normal
        font.family: "M PLUS 2"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: action.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: action.scale = 0.97
        onReleased: action.scale = 1
        onCanceled: action.scale = 1
        onClicked: action.clicked()
    }
}
