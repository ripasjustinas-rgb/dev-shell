import QtQuick
import qs.theme

Rectangle {
    id: root
    property string text: ""
    signal clicked()
    width: 24
    height: 24
    radius: Theme.radius
    color: mouse.containsMouse ? Theme.surfaceHover : Theme.surface

    Text { anchors.centerIn: parent; text: root.text; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13 }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
}
