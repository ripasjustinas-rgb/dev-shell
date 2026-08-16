import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root
    property bool open: false
    property string query: ""
    signal closeRequested()
    Variants { model: Quickshell.screens
        PanelWindow { required property var modelData; screen: modelData; visible: root.open; color: Theme.overlay; exclusionMode: ExclusionMode.Ignore; anchors { top: true; bottom: true; left: true; right: true }; focusable: true
            Keys.onEscapePressed: root.closeRequested()
            MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
            Rectangle { anchors.centerIn: parent; width: Math.min(parent.width - 80, 900); height: Math.min(parent.height - 100, 600); radius: Theme.radiusLarge; color: Theme.background; border.color: Theme.border
                MouseArea { anchors.fill: parent }
                ColumnLayout { anchors.fill: parent; anchors.margins: 20; spacing: 14
                    Text { text: "Overview"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 19; font.bold: true }
                    TextInput { id: search; Layout.fillWidth: true; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 14; text: root.query; onTextChanged: root.query = text.toLowerCase(); Keys.onEscapePressed: root.closeRequested(); Rectangle { z: -1; anchors.fill: parent; anchors.margins: -9; radius: Theme.radius; color: Theme.elevated } }
                    Flow { Layout.fillWidth: true; Layout.fillHeight: true; spacing: 10
                        Repeater { model: 5
                            delegate: Rectangle { required property int index; readonly property int workspace: index + 1; readonly property var info: { for (const item of Hyprland.workspaces.values) if (item.id === workspace) return item; return null }; width: 160; height: 180; radius: Theme.radius; color: info && info.focused ? Theme.accent : Theme.surface
                                Column { anchors.fill: parent; anchors.margins: 12; spacing: 7; Text { text: "Workspace " + parent.parent.workspace; color: parent.parent.info && parent.parent.info.focused ? Theme.background : Theme.text; font.family: Theme.fontFamily; font.bold: true }
                                    Repeater { model: parent.parent.info ? parent.parent.info.toplevels : null; delegate: Text { required property var modelData; visible: !root.query.length || (modelData.title + " " + modelData.appId).toLowerCase().includes(root.query); width: 136; text: modelData.title || modelData.appId; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10; elide: Text.ElideRight; MouseArea { anchors.fill: parent; onClicked: { Hyprland.dispatch("focuswindow address:" + modelData.address); root.closeRequested() } } } }
                                }
                                MouseArea { anchors.fill: parent; z: -1; onClicked: Hyprland.dispatch("workspace " + parent.workspace) }
                            }
                        }
                    }
                    Text { text: "Type to filter windows · ESC to close"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10 }
                }
            }
            Timer { interval: 1; running: root.open; onTriggered: search.forceActiveFocus() }
        }
    }
}
