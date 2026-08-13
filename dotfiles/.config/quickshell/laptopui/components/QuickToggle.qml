import QtQuick
import qs.theme

Rectangle {
    id: root
    property string icon
    property string label
    property bool active: false
    signal clicked()
    width: 112; height: 66; radius: 14
    color: active ? "#404976" : Theme.surface
    Behavior on color { ColorAnimation { duration: 180 } }
    scale: mouse.pressed ? 0.96 : (mouse.containsMouse ? 1.025 : 1)
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Column {
        anchors.centerIn: parent; spacing: 3
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.icon; color: root.active ? Theme.accent : Theme.text; font.family: Theme.fontFamily; font.pixelSize: 18 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.label; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 9; elide: Text.ElideRight; width: 96; horizontalAlignment: Text.AlignHCenter }
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
}
