import QtQuick
import QtQuick.Layouts
import "../../ui" as UI

Rectangle {
    id: row

    property var theme
    property string icon: ""
    property bool active: false
    property bool hasError: false
    property string title: ""
    property string detail: ""
    default property alias trailing: trailingRow.data

    height: 40
    radius: 6
    color: rowHover.hovered ? Qt.rgba(1, 1, 1, 0.04) : "transparent"

    HoverHandler { id: rowHover }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 6
        spacing: 10

        UI.SvgIcon {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            source: row.icon
            color: row.active
                ? (row.theme ? row.theme.accent : Qt.rgba(0.65, 0.55, 0.85, 1))
                : (row.theme ? row.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90))
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: row.title
                textFormat: Text.PlainText
                color: row.theme ? row.theme.textPrimary : Qt.rgba(0.92, 0.92, 0.96, 0.92)
                font.pixelSize: 11
                font.family: "M PLUS 2"
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: row.detail
                textFormat: Text.PlainText
                color: row.hasError
                    ? (row.theme ? row.theme.danger : Qt.rgba(0.95, 0.45, 0.55, 1))
                    : row.active
                        ? (row.theme ? row.theme.accent : Qt.rgba(0.65, 0.55, 0.85, 1))
                        : (row.theme ? row.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.65))
                font.pixelSize: 9
                font.family: "M PLUS 2"
                opacity: row.hasError ? 1 : (row.active ? 0.9 : 0.65)
                elide: Text.ElideRight
            }
        }

        RowLayout {
            id: trailingRow
            spacing: 6
        }
    }
}
