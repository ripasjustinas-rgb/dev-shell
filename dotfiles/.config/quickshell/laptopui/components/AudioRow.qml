import QtQuick
import QtQuick.Layouts
import qs.theme

RowLayout {
    id: root
    property string icon
    property string title
    property string value
    property bool muted
    signal decrease()
    signal increase()
    signal mute()
    Layout.fillWidth: true
    spacing: 6

    Text { text: root.icon; color: root.muted ? Theme.danger : Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 16 }
    Text { text: root.title; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 12; Layout.fillWidth: true }
    AudioAction { text: "−"; onClicked: root.decrease() }
    Text { text: root.value; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; width: 34 }
    AudioAction { text: "+"; onClicked: root.increase() }
    AudioAction { text: root.muted ? "󰍭" : "󰏤"; onClicked: root.mute() }
}
