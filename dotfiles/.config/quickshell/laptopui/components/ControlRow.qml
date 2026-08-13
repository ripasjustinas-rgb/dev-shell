import QtQuick
import QtQuick.Layouts
import qs.theme

Rectangle {
    id: root
    property string icon
    property string title
    property string value
    signal decrease()
    signal increase()
    signal toggle()
    Layout.fillWidth: true
    implicitHeight: 42
    radius: 12
    color: Theme.surface
    RowLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 8
        Text { text: root.icon; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 18 }
        Text { text: root.title; color: Theme.text; font.family: Theme.fontFamily; Layout.fillWidth: true }
        SmallAction { text: "−"; onClicked: root.decrease() }
        Text { text: root.value; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11; width: 36; horizontalAlignment: Text.AlignHCenter }
        SmallAction { text: "+"; onClicked: root.increase() }
        SmallAction { text: "󰏤"; onClicked: root.toggle() }
    }
}
