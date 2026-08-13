import Quickshell.Services.SystemTray
import QtQuick

Row {
    spacing: 2

    Repeater {
        model: SystemTray.items

        Item {
            required property var modelData
            width: 24
            height: 26

            Image {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: parent.modelData.icon
                sourceSize.width: width
                sourceSize.height: height
            }

            MouseArea {
                anchors.fill: parent
                onClicked: parent.modelData.activate()
            }
        }
    }
}
