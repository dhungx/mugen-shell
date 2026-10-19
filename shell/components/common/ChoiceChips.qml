pragma ComponentBehavior: Bound
import QtQuick

Row {
    id: root

    property var theme
    property var options: []
    property var current

    signal picked(var value)

    spacing: 6

    Repeater {
        model: root.options

        Chip {
            required property var modelData

            theme: root.theme
            label: modelData.label
            selected: root.current === modelData.value
            onClicked: root.picked(modelData.value)
        }
    }
}
