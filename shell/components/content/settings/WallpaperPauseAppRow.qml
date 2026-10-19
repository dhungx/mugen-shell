import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../lib" as Theme

Rectangle {
    id: row

    required property var modelData
    property var theme
    property var pausedApps: []
    property var toplevels: []

    signal toggled(string appId)

    readonly property bool checked: pausedApps.indexOf(modelData) !== -1
    readonly property var entry: {
        DesktopEntries.applications.values
        return DesktopEntries.heuristicLookup(modelData)
    }
    readonly property string iconSource: entry && entry.icon ? Quickshell.iconPath(entry.icon, true) : ""
    readonly property var topWindow: {
        for (let i = 0; i < toplevels.length; i++) {
            if (toplevels[i].appId === modelData)
                return toplevels[i]
        }
        return null
    }
    readonly property string windowTitle: topWindow && topWindow.title ? topWindow.title : ""
    readonly property bool showIcon: iconSource !== "" && appIcon.status !== Image.Error

    height: 36
    radius: 6
    color: checked
        ? (theme ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.18) : Qt.rgba(0.65, 0.55, 0.85, 0.18))
        : (rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")
    Behavior on color { ColorAnimation { duration: Theme.Motion.micro } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Item {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: appIcon
                anchors.fill: parent
                visible: row.showIcon
                asynchronous: true
                source: row.iconSource
                sourceSize.width: 36
                sourceSize.height: 36
                fillMode: Image.PreserveAspectFit
            }

            Rectangle {
                anchors.fill: parent
                visible: !row.showIcon
                radius: 4
                color: Qt.rgba(1, 1, 1, 0.10)

                Text {
                    anchors.centerIn: parent
                    text: row.modelData.charAt(0).toUpperCase()
                    textFormat: Text.PlainText
                    color: row.theme ? row.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                    font.pixelSize: 10
                    font.family: "M PLUS 2"
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: row.entry ? row.entry.name : (row.windowTitle !== "" ? row.windowTitle : row.modelData)
                textFormat: Text.PlainText
                color: row.theme ? row.theme.textPrimary : Qt.rgba(0.92, 0.92, 0.96, 0.92)
                font.pixelSize: 11
                font.family: "M PLUS 2"
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: row.topWindow ? row.modelData : row.modelData + " · not running"
                textFormat: Text.PlainText
                color: row.theme ? row.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.65)
                font.pixelSize: 9
                font.family: "M PLUS 2"
                opacity: 0.65
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: pill
            Layout.preferredWidth: 36
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            radius: 10
            color: row.checked
                ? (row.theme ? Qt.rgba(row.theme.accent.r, row.theme.accent.g, row.theme.accent.b, 0.55) : Qt.rgba(0.65, 0.55, 0.85, 0.55))
                : Qt.rgba(0.3, 0.3, 0.36, 0.5)
            border.width: 1
            border.color: row.checked
                ? (row.theme ? row.theme.accent : Qt.rgba(0.65, 0.55, 0.85, 0.95))
                : Qt.rgba(1, 1, 1, 0.10)
            Behavior on color { ColorAnimation { duration: Theme.Motion.fast } }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: row.theme ? row.theme.textPrimary : Qt.rgba(0.95, 0.95, 1.0, 0.95)
                y: 3
                x: row.checked ? pill.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: Theme.Motion.fast; easing.type: Easing.OutCubic } }
            }
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.toggled(row.modelData)
    }
}
