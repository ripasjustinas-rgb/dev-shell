import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme

Item {
    id: root
    property bool open: false
    property string query: ""
    property int selectedIndex: 0
    property real parallaxX: 0
    property real parallaxY: 0
    signal closeRequested()
    readonly property var actions: [
        { title: "Lock screen", category: "Session", run: () => Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/laptopui-lock"]) },
        { title: "Power menu", category: "Session", run: () => Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "togglePower"]) },
        { title: "Full screenshot", category: "Capture", run: () => Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/laptopui-screenshot", "full"]) },
        { title: "Region screenshot", category: "Capture", run: () => Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/laptopui-screenshot", "region"]) },
        { title: "Toggle Do Not Disturb", category: "Shell", run: () => SettingsState.toggleDnd() },
        { title: "Toggle calm mode", category: "Shell", run: () => SettingsState.toggleCalmMode() },
        { title: "Reload Quickshell", category: "Shell", run: () => Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/laptopui-reload"]) },
        { title: "Wi-Fi and Bluetooth", category: "Connectivity", run: () => Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "toggleConnectivity"]) },
        { title: "Audio devices", category: "System", run: () => Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "toggleControlCenter"]) },
        { title: "Power profile", category: "System", run: () => Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "toggleControlCenter"]) },
        { title: "Next wallpaper", category: "Appearance", run: () => Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/laptopui-wallpaper-next"]) },
        { title: "Control center", category: "Shell", run: () => Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "toggleControlCenter"]) },
        { title: "Notifications", category: "Shell", run: () => Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "toggleNotifications"]) }
    ]
    function matchingActions() { const needle = query.toLowerCase(); return actions.filter(action => !needle.length || (action.title + " " + action.category).toLowerCase().includes(needle)) }
    function activate(index) { const values = matchingActions(); if (values.length) { values[Math.min(index, values.length - 1)].run(); closeRequested() } }
    Variants { model: Quickshell.screens
        PanelWindow { required property var modelData; screen: modelData; visible: root.open; color: Theme.overlay; exclusionMode: ExclusionMode.Ignore; anchors { top: true; bottom: true; left: true; right: true } focusable: true
            MouseArea { anchors.fill: parent; hoverEnabled: true; onPositionChanged: mouse => { if (!SettingsState.reducedMotion) { root.parallaxX = (mouse.x / width - 0.5) * 5; root.parallaxY = (mouse.y / height - 0.5) * 5 } } onClicked: root.closeRequested() }
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 112; width: 560; height: 430; radius: Theme.radiusLarge; color: Theme.background; border.color: Theme.border
                transform: Translate { x: root.parallaxX; y: root.parallaxY }
                MouseArea { anchors.fill: parent }
                ColumnLayout { anchors.fill: parent; anchors.margins: 18; spacing: 12
                    TextInput { id: input; Layout.fillWidth: true; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 15; text: root.query
                        onTextChanged: { root.query = text; root.selectedIndex = 0 }
                        Keys.onEscapePressed: root.closeRequested()
                        Keys.onReturnPressed: root.activate(root.selectedIndex)
                        Keys.onDownPressed: { const n = root.matchingActions().length; if (n) root.selectedIndex = (root.selectedIndex + 1) % n }
                        Keys.onUpPressed: { const n = root.matchingActions().length; if (n) root.selectedIndex = (root.selectedIndex - 1 + n) % n }
                        Rectangle { z: -1; anchors.fill: parent; anchors.margins: -12; radius: Theme.radius; color: Theme.elevated }
                    }
                    ListView { id: list; Layout.fillWidth: true; Layout.fillHeight: true; model: root.matchingActions(); clip: true; spacing: 4
                        delegate: Rectangle { required property var modelData; required property int index; width: list.width; height: 48; radius: Theme.radius; color: index === root.selectedIndex ? Theme.surfaceHover : Theme.surface
                            RowLayout { anchors.fill: parent; anchors.margins: 10; Text { text: modelData.title; color: Theme.text; font.family: Theme.fontFamily; Layout.fillWidth: true } Text { text: modelData.category; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10 } }
                            MouseArea { anchors.fill: parent; onClicked: root.activate(index) }
                        }
                    }
                    Text { text: "Command palette · ↑ ↓ Enter · ESC"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10 }
                }
            }
            Timer { interval: 1; running: root.open; onTriggered: { root.query = ""; input.forceActiveFocus() } }
        }
    }
}
