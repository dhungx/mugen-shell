import QtQuick
import QtQuick.Layouts

Rectangle {
    id: well

    property var theme
    property var model: []
    property Component rowDelegate
    property string placeholder: ""
    property int maxHeight: 0

    readonly property int count: list.count

    Layout.fillWidth: true
    implicitHeight: (list.count === 0 ? 40
        : (maxHeight > 0 ? Math.min(list.contentHeight, maxHeight) : list.contentHeight)) + 8
    radius: 10
    color: theme ? theme.surfaceInsetSubtle : Qt.rgba(0, 0, 0, 0.3)
    border.width: 1
    border.color: theme ? theme.surfaceBorder : Qt.rgba(1, 1, 1, 0.12)
    clip: true

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 4
        spacing: 0
        model: well.model
        delegate: well.rowDelegate
        cacheBuffer: 1000
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        clip: true
    }

    Text {
        anchors.centerIn: parent
        visible: list.count === 0
        text: well.placeholder
        color: well.theme ? well.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.65)
        font.pixelSize: 11
        font.family: "M PLUS 2"
        font.italic: true
        opacity: 0.65
    }
}
