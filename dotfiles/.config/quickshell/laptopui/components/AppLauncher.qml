import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root
    property bool open: false
    signal closeRequested()
    property string query: ""
    property string searchText: ""
    property int selectedIndex: 0
    // Chosen daily drivers. Missing entries are simply omitted on another host.
    property var pinnedIds: ["Firefox", "Kitty", "Dolphin", "Htop"]
    property var recentIds: ["Htop", "Firefox", "Kitty", "Dolphin"]
    property string pinStatePath: Quickshell.env("HOME") + "/.local/state/laptopui/pinned-apps"
    property string recentStatePath: Quickshell.env("HOME") + "/.local/state/laptopui/recent-apps"

    function fuzzyMatch(haystack, needle) {
        let cursor = 0
        for (const character of needle) { cursor = haystack.indexOf(character, cursor); if (cursor < 0) return false; cursor++ }
        return true
    }

    function resolveEntry(key) {
        const exact = DesktopEntries.applications.values.find(entry => entry.id === key)
        return exact || DesktopEntries.heuristicLookup(key)
    }
    function entries(ids) {
        return ids.map(id => resolveEntry(id)).filter(entry => entry !== null)
    }
    function matchingEntries() {
        return DesktopEntries.applications.values.filter(entry => {
            const haystack = (entry.name + " " + entry.genericName + " " + entry.comment).toLowerCase()
            return !entry.noDisplay && fuzzyMatch(haystack, query)
        })
    }
    function remember(entry) {
        recentIds = [entry.id, ...recentIds.filter(id => id !== entry.id)].slice(0, 4)
        recentWriter.exec(["sh", "-c", "mkdir -p \"$HOME/.local/state/laptopui\" && printf '%s\\n' '" + recentIds.join("' '") + "' > \"$HOME/.local/state/laptopui/recent-apps\""])
    }
    function launch(entry) {
        remember(entry)
        entry.execute()
        closeRequested()
    }
    function togglePin(entry) {
        pinWriter.exec([Quickshell.env("HOME") + "/.local/bin/laptopui-launcher-pin", "toggle", entry.id, pinnedIds.join(",")])
        pinRefresh.restart()
    }
    function refreshPins() { pinReader.exec(["sh", "-c", "cat \"$HOME/.local/state/laptopui/pinned-apps\" 2>/dev/null || true"]) }
    function reset() {
        query = ""
        searchText = ""
        selectedIndex = 0
    }
    Process {
        id: pinReader
        stdout: StdioCollector {
            onStreamFinished: {
                const values = text.trim().split("\n").filter(value => value.length)
                if (values.length) root.pinnedIds = values
            }
        }
    }
    Process { id: pinWriter }
    Process { id: recentWriter }
    Process { id: recentReader; stdout: StdioCollector { onStreamFinished: { const values = text.trim().split("\n").filter(value => value.length); if (values.length) root.recentIds = values } } }
    Timer { id: pinRefresh; interval: 150; onTriggered: root.refreshPins() }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open
            color: Theme.overlay
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            focusable: true
            onVisibleChanged: {
                if (visible) { root.reset(); root.refreshPins(); recentReader.exec(["sh", "-c", "cat \"$HOME/.local/state/laptopui/recent-apps\" 2>/dev/null || true"]) }
            }

            MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 112
                width: 620; height: 510; radius: 20
                color: Theme.background; border.color: Theme.border; border.width: 1
                opacity: root.open ? 1 : 0
                scale: root.open ? 1 : 0.96
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 18; spacing: 14
                    Rectangle {
                        Layout.fillWidth: true; height: 54; radius: 14; color: Theme.elevated
                        Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "󰍉"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 19 }
                        TextInput {
                            id: search
                            anchors.left: parent.left; anchors.leftMargin: 46; anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 15; clip: true
                            text: root.searchText
                            onTextChanged: { root.searchText = text; root.query = text.toLowerCase(); root.selectedIndex = 0 }
                            Keys.onEscapePressed: root.closeRequested()
                            Keys.onReturnPressed: {
                                const matches = root.matchingEntries()
                                if (root.query.length && matches.length) root.launch(matches[Math.min(root.selectedIndex, matches.length - 1)])
                            }
                            Keys.onDownPressed: { const count = root.matchingEntries().length; if (count) root.selectedIndex = (root.selectedIndex + 1) % count }
                            Keys.onUpPressed: { const count = root.matchingEntries().length; if (count) root.selectedIndex = (root.selectedIndex - 1 + count) % count }
                        }
                        Timer { interval: 1; running: root.open; onTriggered: search.forceActiveFocus() }
                        Text { visible: !search.text.length; anchors.left: parent.left; anchors.leftMargin: 46; anchors.verticalCenter: parent.verticalCenter; text: "Search applications…"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 15 }
                    }

                    Item {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        visible: !root.query.length
                        ColumnLayout {
                            anchors.fill: parent; spacing: 12
                            Text { text: "Pinned"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11 }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                Repeater { model: root.entries(root.pinnedIds)
                                    delegate: LauncherTile { required property var modelData; entry: modelData; pinned: true; onActivated: root.launch(entry); onTogglePin: root.togglePin(entry) }
                                }
                            }
                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }
                            Text { text: "Recent"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11 }
                            ListView {
                                id: recentList
                                Layout.fillWidth: true; spacing: 8
                                Layout.preferredHeight: Math.min(contentHeight, 4 * 52)
                                clip: true
                                model: root.entries(root.recentIds)
                                delegate: Rectangle {
                                    required property var modelData
                                    width: recentList.width; height: 48; radius: 10
                                    color: recentMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 10; spacing: 12
                                        IconImage { source: Quickshell.iconPath(modelData.icon || "application-x-executable"); implicitSize: 26; Layout.preferredWidth: 26; Layout.preferredHeight: 26 }
                                        ColumnLayout { Layout.fillWidth: true; spacing: 1
                                            Text { text: modelData.name; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                                            Text { text: modelData.genericName || modelData.comment; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                                        }
                                    }
                                    MouseArea {
                                        id: recentMouse; anchors.fill: parent; hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.RightButton) root.togglePin(modelData)
                                            else root.launch(modelData)
                                        }
                                    }
                                }
                            }
                            Item { Layout.fillHeight: true }
                        }
                    }

                    ListView {
                        id: appList
                        visible: root.query.length > 0
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4
                        model: DesktopEntries.applications
                        delegate: Rectangle {
                            required property var modelData
                            readonly property string haystack: (modelData.name + " " + modelData.genericName + " " + modelData.comment).toLowerCase()
                            visible: !modelData.noDisplay && root.fuzzyMatch(haystack, root.query)
                            width: appList.width; height: visible ? 54 : 0; radius: 10
                            color: rowMouse.containsMouse ? Theme.surfaceHover : "transparent"
                            Behavior on height { NumberAnimation { duration: 100 } }
                            RowLayout { anchors.fill: parent; anchors.margins: 9; spacing: 12
                                IconImage { source: Quickshell.iconPath(modelData.icon || "application-x-executable"); implicitSize: 28; Layout.preferredWidth: 28; Layout.preferredHeight: 28 }
                                ColumnLayout { Layout.fillWidth: true; spacing: 1
                                    Text { text: modelData.name; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                                    Text { text: modelData.genericName || modelData.comment; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }
                            MouseArea {
                                id: rowMouse; anchors.fill: parent; hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) root.togglePin(modelData)
                                    else root.launch(modelData)
                                }
                            }
                        }
                    }
                    Text { text: root.query.length ? "Search results · ESC to close" : "Recent and pinned apps · ESC to close"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10 }
                }
            }
        }
    }
}
