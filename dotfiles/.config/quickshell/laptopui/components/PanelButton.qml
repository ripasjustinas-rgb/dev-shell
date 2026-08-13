import QtQuick
import qs.theme

Rectangle {
    id: root
    property string label: ""
    property string tooltip: ""
    property color labelColor: Theme.muted
    signal clicked()
    implicitWidth: Math.max(30, labelText.implicitWidth + 12)
    implicitHeight: 26
    radius: Theme.radius
    color: mouse.containsMouse ? Theme.elevated : Theme.surface
    scale: mouse.pressed ? 0.94 : (mouse.containsMouse ? 1.04 : 1)
    Behavior on color { ColorAnimation { duration: 130 } }
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.labelColor
        font.family: Theme.fontFamily
        font.pixelSize: 15
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
