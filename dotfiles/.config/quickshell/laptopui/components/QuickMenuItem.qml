import QtQuick
import qs.theme

Rectangle {
    id: root
    property string text: ""
    property bool active: false
    signal clicked()
    width: parent ? parent.width : 170; height: 32; radius: 7
    color: mouse.containsMouse || active ? Theme.surfaceHover : Theme.surface
    Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 9; text: root.text; color: root.active ? Theme.accent : Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11 }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
}
