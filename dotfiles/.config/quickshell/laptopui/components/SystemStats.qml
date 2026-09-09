import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Item {
    id: root
    implicitWidth: statsRow.implicitWidth
    implicitHeight: Theme.panelContentHeight - 6

    RowLayout {
        id: statsRow
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: [
                { icon: "󰍛", value: Math.round(SystemHealth.cpuUsage) + "%" },
                { icon: "󰘚", value: SystemHealth.ramPercent + "%" }
            ]
            Rectangle {
                required property var modelData
                Layout.preferredWidth: 70
                Layout.fillHeight: true
                radius: Theme.radius
                color: statsMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                border.width: 1
                border.color: Theme.glassBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 7
                    anchors.rightMargin: 7
                    spacing: 5

                    Text {
                        Layout.preferredWidth: 20
                        Layout.fillHeight: true
                        text: modelData.icon
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: modelData.value
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MouseArea {
                    id: statsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["kitty", "btop"])
                }
            }
        }
    }

}
