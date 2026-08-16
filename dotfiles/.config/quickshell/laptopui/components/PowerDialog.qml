import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root
    property bool open: false
    signal closeRequested()
    property string pending: ""
    function choose(action) { pending = action }
    function confirm() {
        if (pending === "Logout") Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
        else if (pending === "Restart") Quickshell.execDetached(["systemctl", "reboot"])
        else if (pending === "Shutdown") Quickshell.execDetached(["systemctl", "poweroff"])
    }
    Variants { model: Quickshell.screens
        PanelWindow { required property var modelData; screen: modelData; visible: root.open; color: Theme.overlay; exclusionMode: ExclusionMode.Ignore; anchors { top: true; bottom: true; left: true; right: true }
            focusable: true
            Keys.onEscapePressed: {
                if (root.pending.length) root.pending = ""
                else root.closeRequested()
            }
            Shortcut { enabled: root.open; sequence: "Escape"; onActivated: { if (root.pending.length) root.pending = ""; else root.closeRequested() } }
            MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
            Rectangle { anchors.centerIn: parent; width: 370; height: root.pending.length ? 220 : 180; radius: 20; color: Theme.background; border.color: Theme.border; border.width: 1; scale: root.open ? 1 : 0.94; focus: root.open
                Keys.onEscapePressed: { if (root.pending.length) root.pending = ""; else root.closeRequested() }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                MouseArea { anchors.fill: parent }
                ColumnLayout { anchors.fill: parent; anchors.margins: 20; spacing: 14
                    Text { text: root.pending.length ? (root.pending + "?") : "Power"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 18; font.bold: true }
                    Text { visible: root.pending.length; text: "This will end the current session."; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11 }
                    RowLayout { visible: !root.pending.length; Layout.fillWidth: true; spacing: 10
                        PowerAction { icon: "󰍃"; label: "Logout"; onClicked: root.choose("Logout") }
                        PowerAction { icon: "󰜉"; label: "Restart"; onClicked: root.choose("Restart") }
                        PowerAction { icon: "󰐥"; label: "Shutdown"; danger: true; onClicked: root.choose("Shutdown") }
                    }
                    RowLayout { visible: root.pending.length; Layout.fillWidth: true; Item { Layout.fillWidth: true }
                        SmallAction { width: 74; text: "Cancel"; onClicked: root.pending = "" }
                        SmallAction { width: 80; text: "Confirm"; onClicked: root.confirm() }
                    }
                }
            }
        }
    }
}
