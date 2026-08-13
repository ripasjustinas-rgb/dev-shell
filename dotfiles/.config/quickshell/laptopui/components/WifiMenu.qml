import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.theme

PopupWindow {
    id: root
    property Item anchorItem
    property var wifiDevice: {
        for (const device of Networking.devices.values) {
            if (device.type === DeviceType.Wifi) return device
        }
        return null
    }

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
    implicitWidth: 320
    implicitHeight: content.implicitHeight
    visible: false
    color: "transparent"
    grabFocus: true

    onVisibleChanged: {
        if (visible && wifiDevice) wifiDevice.scannerEnabled = true
    }

    Rectangle {
        id: content
        anchors.fill: parent
        anchors.topMargin: 6
        radius: Theme.radius
        color: Theme.surface
        implicitHeight: 310

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Wi-Fi"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.wifiDevice && Networking.wifiEnabled ? "ON" : "OFF"
                    color: Networking.wifiEnabled ? Theme.accent : Theme.muted
                    font.family: Theme.fontFamily
                }
                MouseArea {
                    width: 36
                    height: 24
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.wifiDevice ? root.wifiDevice.networks : null
                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 38
                    radius: Theme.radius
                    color: networkMouse.containsMouse ? Theme.surfaceHover : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        Text {
                            text: modelData.name
                            color: modelData.connected ? Theme.accent : Theme.text
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.connected ? "connected" : Math.round(modelData.signalStrength) + "%"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: networkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (modelData.connected) modelData.disconnect()
                            else if (modelData.known) modelData.connect()
                            else Quickshell.execDetached(["kitty", "sh", "-lc", "nmcli device wifi connect '" + modelData.name.replace(/'/g, "'\\\"'\\\"'") + "'; printf '\\nPress Enter to close... '; read _"])
                        }
                    }
                }
            }
        }
    }
}
