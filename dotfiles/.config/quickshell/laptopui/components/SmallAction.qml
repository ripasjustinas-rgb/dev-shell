import QtQuick
import qs.theme

Rectangle {
    id: root
    property string text: ""
    signal clicked()
    width: 25; height: 25; radius: 7
    color: mouse.containsMouse ? Theme.surfaceHover : Theme.surface
    Behavior on color { ColorAnimation { duration: 120 } }
    Text { anchors.centerIn: parent; text: root.text; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13 }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
}
