import QtQuick
import QtQuick.Layouts
import qs.theme

Rectangle {
    id: root
    property string icon
    property string title
    property string value
    property real level: 0
    property bool muted: false
    property bool muteAvailable: false
    property string muteIcon: ""
    property bool deviceSelectionAvailable: false
    property bool microphone: false
    signal levelRequested(real level)
    signal muteRequested()
    signal deviceSelectionChanged()
    Layout.fillWidth: true
    implicitHeight: 46
    radius: 12
    color: Theme.surface
    RowLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 8
        Text { text: root.icon; color: root.muted ? Theme.danger : Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 18 }
        Text { text: root.title; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 12; Layout.preferredWidth: 72 }
        Item {
            id: slider
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            readonly property real clampedLevel: Math.max(0, Math.min(100, root.level))
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 6; radius: 3
                color: Theme.elevated
                Rectangle {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * slider.clampedLevel / 100; height: parent.height; radius: parent.radius
                    color: root.muted ? Theme.muted : Theme.accent
                }
                Rectangle {
                    x: parent.width * slider.clampedLevel / 100 - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14; height: 14; radius: 7
                    color: root.muted ? Theme.muted : Theme.text
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function setLevel(mouse) {
                    root.levelRequested(Math.max(0, Math.min(100, mouse.x / width * 100)))
                }
                onPressed: mouse => setLevel(mouse)
                onPositionChanged: mouse => { if (pressed) setLevel(mouse) }
            }
        }
        Text { text: root.value; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11; width: 36; horizontalAlignment: Text.AlignHCenter }
        Rectangle {
            visible: root.muteAvailable
            Layout.preferredWidth: visible ? 26 : 0
            Layout.preferredHeight: 26
            radius: 7
            color: muteMouse.containsMouse ? Theme.surfaceHover : Theme.elevated
            Text { anchors.centerIn: parent; text: root.muteIcon || (root.muted ? "󰖁" : "󰕾"); color: root.muted ? Theme.danger : Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13 }
            MouseArea { id: muteMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.muteRequested() }
        }
        Rectangle {
            id: deviceButton
            visible: root.deviceSelectionAvailable
            Layout.preferredWidth: visible ? 24 : 0
            Layout.preferredHeight: 26
            radius: 7
            color: deviceMouse.containsMouse ? Theme.surfaceHover : Theme.elevated
            Text { anchors.centerIn: parent; text: "⌄"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 16 }
            MouseArea { id: deviceMouse; anchors.fill: parent; hoverEnabled: true; onClicked: deviceMenu.visible = !deviceMenu.visible }
        }
    }
    DeviceSelector {
        id: deviceMenu
        anchorItem: deviceButton
        microphone: root.microphone
        onDeviceSelected: root.deviceSelectionChanged()
    }
}
