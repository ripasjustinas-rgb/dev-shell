import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

RowLayout {
    spacing: 3

    Repeater {
        model: 5

        Rectangle {
            required property int index
            readonly property int workspace: index + 1
            readonly property var workspaceInfo: WindowState.workspace(workspace)
            readonly property bool active: workspaceInfo && workspaceInfo.focused
            readonly property bool occupied: workspaceInfo && workspaceInfo.toplevels.values.length > 0
            implicitWidth: 28
            implicitHeight: 26
            radius: Theme.radius
            color: active ? Theme.accent : (mouse.containsMouse ? Theme.surfaceHover : Theme.surface)

            Text {
                anchors.centerIn: parent
                text: parent.workspace
                color: parent.active ? Theme.background : Theme.muted
                font.family: Theme.fontFamily
                font.bold: parent.active
            }

            Rectangle {
                visible: parent.occupied
                width: 4
                height: 4
                radius: 2
                color: parent.active ? Theme.background : Theme.accent
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + parent.workspace + " })")
            }
        }
    }

    PanelButton {
        id: wallpaperButton
        label: "󰸉"
        tooltip: "Choose wallpaper"
        onClicked: wallpaperPicker.open = !wallpaperPicker.open
    }

    WallpaperPicker { id: wallpaperPicker }

    UpdateButton {}
}
