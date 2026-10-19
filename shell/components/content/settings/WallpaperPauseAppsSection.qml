pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../../lib" as Theme

Rectangle {
    id: root

    required property var theme
    required property var modeManager
    required property var settingsManager

    property bool isExpanded: false
    property string filterText: ""
    property var knownSaved: []
    property var rowIds: []

    readonly property var openIds: Theme.WallpaperRules.openAppIds(ToplevelManager.toplevels.values)
    readonly property var visibleIds: {
        void DesktopEntries.applications.values
        const q = filterText.trim().toLowerCase()
        if (q === "") return rowIds
        return rowIds.filter(id => {
            const entry = DesktopEntries.heuristicLookup(id)
            const name = entry && entry.name ? entry.name.toLowerCase() : ""
            return id.toLowerCase().indexOf(q) !== -1 || name.indexOf(q) !== -1
        })
    }
    readonly property int pausedCount: settingsManager ? settingsManager.wallpaperPauseApps.length : 0
    readonly property int expandedHeight: 64 + contentColumn.implicitHeight + 16

    width: parent ? parent.width : 420
    height: isExpanded ? expandedHeight : 64
    color: theme ? theme.surfaceInsetSubtle : Qt.rgba(0, 0, 0, 0.25)
    radius: 20
    border.width: 1
    border.color: theme ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2) : Qt.rgba(0.65, 0.55, 0.85, 0.2)
    clip: true

    function bump() {
        if (modeManager && modeManager.isMode("settings")) modeManager.bump()
    }

    function summary() {
        if (pausedCount === 0) return "None"
        return pausedCount === 1 ? "1 app" : pausedCount + " apps"
    }

    function absorbSaved() {
        const saved = settingsManager ? settingsManager.wallpaperPauseApps : []
        const added = saved.filter(id => knownSaved.indexOf(id) === -1)
        if (added.length > 0)
            knownSaved = knownSaved.concat(added)
    }

    function refreshRows() {
        const next = Theme.WallpaperRules.pauseAppRowIds(openIds, knownSaved)
        if (JSON.stringify(next) !== JSON.stringify(rowIds))
            rowIds = next
    }

    function toggleApp(appId) {
        if (!settingsManager) return
        const current = settingsManager.wallpaperPauseApps
        settingsManager.wallpaperPauseApps = current.indexOf(appId) !== -1
            ? current.filter(id => id !== appId)
            : current.concat([appId])
        settingsManager.saveSettings()
        bump()
    }

    onOpenIdsChanged: refreshRows()
    onKnownSavedChanged: refreshRows()

    Component.onCompleted: {
        absorbSaved()
        refreshRows()
    }

    Connections {
        target: root.settingsManager

        function onWallpaperPauseAppsChanged() {
            root.absorbSaved()
        }
    }

    Behavior on height {
        NumberAnimation { duration: Theme.Motion.standard; easing.type: Easing.OutCubic }
    }

    MouseArea {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 64
        cursorShape: Qt.PointingHandCursor

        TapHandler {
            onTapped: {
                root.isExpanded = !root.isExpanded
                root.bump()
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Pause for apps"
                color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                font.letterSpacing: 0.5
                elide: Text.ElideRight
            }

            Text {
                text: root.summary()
                color: root.theme ? root.theme.textPrimary : Qt.rgba(0.92, 0.92, 0.96, 0.90)
                font.pixelSize: 11
                font.family: "M PLUS 2"
                font.italic: root.pausedCount === 0
                opacity: 0.85
            }

            Text {
                text: root.isExpanded ? "▴" : "▾"
                color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.90)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                opacity: 0.7
            }
        }
    }

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 4
        spacing: 10
        visible: root.isExpanded

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: "Video wallpapers pause while one of these apps has a window open. Open an app to add it here."
            color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.60)
            font.pixelSize: 10
            font.family: "M PLUS 2"
            opacity: 0.65
            wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            color: "transparent"
            radius: 8
            border.width: 1
            border.color: filterInput.activeFocus
                ? (root.theme ? root.theme.glowPrimary : Qt.rgba(0.65, 0.55, 0.85, 1))
                : (root.theme ? root.theme.surfaceBorder : Qt.rgba(1, 1, 1, 0.18))
            Behavior on border.color { ColorAnimation { duration: Theme.Motion.fast } }

            TextInput {
                id: filterInput
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                color: root.theme ? root.theme.textPrimary : Qt.rgba(0.91, 0.91, 0.94, 0.9)
                selectionColor: root.theme ? Qt.rgba(root.theme.glowPrimary.r, root.theme.glowPrimary.g, root.theme.glowPrimary.b, 0.4) : Qt.rgba(0.65, 0.55, 0.85, 0.4)
                font.pixelSize: 12
                font.family: "M PLUS 2"
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                onTextChanged: root.filterText = text

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: "filter apps…"
                    color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.5)
                    font: filterInput.font
                    opacity: filterInput.text.length === 0 ? 0.5 : 0
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 260
            radius: 10
            color: root.theme ? root.theme.surfaceInsetSubtle : Qt.rgba(0, 0, 0, 0.3)
            border.width: 1
            border.color: root.theme ? root.theme.surfaceBorder : Qt.rgba(1, 1, 1, 0.12)
            clip: true

            ListView {
                id: appList
                anchors.fill: parent
                anchors.margins: 4
                spacing: 0
                model: root.visibleIds
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                delegate: WallpaperPauseAppRow {
                    width: ListView.view.width
                    theme: root.theme
                    pausedApps: root.settingsManager ? root.settingsManager.wallpaperPauseApps : []
                    toplevels: ToplevelManager.toplevels.values
                    onToggled: appId => root.toggleApp(appId)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.visibleIds.length === 0
                text: root.filterText.trim() !== "" ? "No matches" : "No apps open"
                color: root.theme ? root.theme.textSecondary : Qt.rgba(0.72, 0.72, 0.82, 0.65)
                font.pixelSize: 11
                font.family: "M PLUS 2"
                font.italic: true
                opacity: 0.65
            }
        }
    }
}
