import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Item {
    id: root

    property bool open: false
    property string query: ""
    property int selectedWorkspace: 1

    signal closeRequested()

    function selectWorkspace(delta) {
        selectedWorkspace = Math.max(1, Math.min(5, selectedWorkspace + delta))
    }

    function activateWorkspace(workspace) {
        // Hyprland's Lua configuration expects a dispatcher object, not the
        // legacy "workspace 2" command string.
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspace + " })")
        closeRequested()
    }

    function activateSelectedWorkspace() {
        activateWorkspace(selectedWorkspace)
    }

    function selectFocusedWorkspace() {
        for (const workspace of Hyprland.workspaces.values) {
            if (workspace.focused) {
                selectedWorkspace = workspace.id
                return
            }
        }
        selectedWorkspace = 1
    }

    function matchesQuery(toplevel) {
        return !query.length || (toplevel.title + " " + toplevel.appId).toLowerCase().includes(query)
    }

    function applicationName(toplevel) {
        return toplevel.appId || toplevel.title || "Unknown application"
    }

    onOpenChanged: {
        if (open) {
            query = ""
            selectFocusedWorkspace()
        }
    }

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

            // PanelWindow is not a QQuickItem in Quickshell 0.3, so attached
            // Keys handlers do not receive events here. Shortcuts remain
            // active while the search TextInput has focus.
            Shortcut {
                sequence: "Escape"
                enabled: root.open
                onActivated: root.closeRequested()
            }

            Shortcut {
                sequence: "Return"
                enabled: root.open
                onActivated: root.activateSelectedWorkspace()
            }

            Shortcut {
                sequence: "Enter"
                enabled: root.open
                onActivated: root.activateSelectedWorkspace()
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeRequested()
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - 64, 1120)
                height: Math.min(parent.height - 72, 680)
                radius: Theme.radiusLarge
                color: Theme.background
                border.color: Theme.border

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Workspaces"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 20
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "← → select · Enter open"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        text: root.query
                        selectByMouse: true
                        onTextChanged: root.query = text.toLowerCase()

                        // TextInput owns the arrow keys, so handle workspace
                        // navigation on the focused item before cursor motion.
                        Keys.priority: Keys.BeforeItem
                        Keys.onEscapePressed: root.closeRequested()
                        Keys.onLeftPressed: root.selectWorkspace(-1)
                        Keys.onRightPressed: root.selectWorkspace(1)

                        Rectangle {
                            z: -1
                            anchors.fill: parent
                            anchors.margins: -10
                            radius: Theme.radius
                            color: Theme.elevated
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 14

                        Repeater {
                            model: 5

                            delegate: Rectangle {
                                id: workspaceCard
                                required property int index
                                readonly property int workspace: index + 1
                                readonly property var info: WindowState.workspace(workspace)
                                readonly property int windowCount: info ? info.toplevels.values.length : 0
                                readonly property bool selected: root.selectedWorkspace === workspace

                                // Keep all five workspaces visible at once.
                                width: (parent.width - 56) / 5
                                height: 286
                                radius: Theme.radius
                                color: selected ? Theme.surfaceHover : Theme.surface
                                border.width: selected ? 2 : 1
                                border.color: selected ? Theme.accent : Theme.border

                                Behavior on color { ColorAnimation { duration: 120 } }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 9

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: "Workspace " + workspaceCard.workspace
                                            color: workspaceCard.selected ? Theme.accent : Theme.text
                                            font.family: Theme.fontFamily
                                            font.bold: true
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text {
                                            text: workspaceCard.windowCount + " windows"
                                            color: Theme.muted
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                        }
                                    }

                                    Rectangle {
                                        id: preview
                                        readonly property var workspaceInfo: parent.parent.info
                                        readonly property int windowCount: workspaceInfo ? workspaceInfo.toplevels.values.length : 0
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 158
                                        radius: 7
                                        color: Theme.background
                                        border.width: 1
                                        border.color: Theme.border
                                        clip: true

                                        Item {
                                            anchors.fill: parent

                                            Rectangle {
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                height: 22
                                                color: Theme.elevated

                                                Text {
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: 8
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "LIVE WINDOW MAP"
                                                    color: Theme.muted
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 8
                                                    font.bold: true
                                                }

                                                Text {
                                                    anchors.right: parent.right
                                                    anchors.rightMargin: 8
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: preview.windowCount ? "● LIVE" : "—"
                                                    color: preview.windowCount ? Theme.accent : Theme.muted
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 8
                                                    font.bold: true
                                                }
                                            }

                                            Repeater {
                                                model: preview.workspaceInfo ? preview.workspaceInfo.toplevels : null

                                                delegate: Rectangle {
                                                    required property int index
                                                    required property var modelData
                                                    visible: root.matchesQuery(modelData)
                                                    x: 8 + (index % 2) * (parent.width * 0.46)
                                                    y: 30 + Math.floor(index / 2) * 56
                                                    width: visible ? Math.max(66, parent.width * (index % 2 ? 0.43 : 0.49)) : 0
                                                    height: visible ? 51 : 0
                                                    radius: 5
                                                    color: modelData.activated ? Theme.accent : Theme.elevated
                                                    border.width: modelData.activated ? 1 : 0
                                                    border.color: Theme.accent

                                                    Rectangle {
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        anchors.top: parent.top
                                                        height: 12
                                                        radius: parent.radius
                                                        color: modelData.activated ? Theme.accent : Theme.surfaceHover
                                                    }

                                                    Text {
                                                        anchors.fill: parent
                                                        anchors.margins: 7
                                                        anchors.topMargin: 16
                                                        text: modelData.title || root.applicationName(modelData)
                                                        color: modelData.activated ? Theme.background : Theme.text
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: 9
                                                        elide: Text.ElideRight
                                                        maximumLineCount: 2
                                                        wrapMode: Text.Wrap
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            Hyprland.dispatch("hl.dsp.window.focus({ address = \"" + modelData.address + "\" })")
                                                            root.closeRequested()
                                                        }
                                                    }
                                                }
                                            }

                                            Text {
                                                visible: preview.windowCount === 0
                                                anchors.centerIn: parent
                                                text: "No windows yet"
                                                color: Theme.muted
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: windowCount ? "Running applications" : "No running applications"
                                        color: Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }

                                    Flow {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 5

                                        Repeater {
                                            model: info ? info.toplevels : null

                                            delegate: Rectangle {
                                                required property var modelData
                                                visible: root.matchesQuery(modelData)
                                                width: visible ? appName.implicitWidth + 14 : 0
                                                height: visible ? 22 : 0
                                                radius: 5
                                                color: modelData.activated ? Theme.accent : Theme.elevated

                                                Text {
                                                    id: appName
                                                    anchors.centerIn: parent
                                                    text: root.applicationName(modelData)
                                                    color: modelData.activated ? Theme.background : Theme.text
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 10
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    z: -1
                                    onClicked: {
                                        root.selectedWorkspace = parent.workspace
                                        root.activateSelectedWorkspace()
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "Type to filter windows · ESC to close"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }
            }

            Timer {
                interval: 1
                running: root.open
                onTriggered: search.forceActiveFocus()
            }
        }
    }
}
