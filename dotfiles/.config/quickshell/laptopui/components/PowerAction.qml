import QtQuick
import qs.theme

Rectangle {
    id: root
    property string icon
    property string label
    property bool danger: false
    signal clicked()
    width: 102; height: 80; radius: 13
    color: mouse.containsMouse ? Theme.surfaceHover : Theme.surface
    Behavior on color { ColorAnimation { duration: 150 } }
    Column { anchors.centerIn: parent; spacing: 5
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.icon; color: root.danger ? Theme.danger : Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 23 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.label; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11 }
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
}
