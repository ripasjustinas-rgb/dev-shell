import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.theme

Rectangle {
    id: root
    required property var entry
    property bool pinned: false
    signal activated()
    signal togglePin()
    Layout.fillWidth: true
    Layout.preferredHeight: 92
    radius: 14
    color: mouse.containsMouse ? Theme.elevated : Theme.surface
    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    scale: mouse.containsMouse ? 1.025 : 1
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 7
        IconImage { source: Quickshell.iconPath(root.entry.icon || "application-x-executable"); implicitSize: 30; Layout.preferredWidth: 30; Layout.preferredHeight: 30 }
        Text { text: root.entry.name; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
    }
    Text {
        visible: root.pinned
        z: 2
        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 7
        text: "󰐃"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 12
        MouseArea { anchors.fill: parent; onClicked: root.togglePin() }
    }
    MouseArea {
        id: mouse; anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.togglePin()
            else root.activated()
        }
    }
}
