import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme

PopupWindow {
    id: root
    property Item anchorItem
    property var wifiDevice: {
        for (const device of Networking.devices.values) if (device.type === DeviceType.Wifi) return device
        return null
    }
    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
    implicitWidth: 330
    implicitHeight: content.implicitHeight
    visible: false
    color: "transparent"
    grabFocus: true
    onVisibleChanged: { if (visible && wifiDevice) wifiDevice.scannerEnabled = true; if (visible) BluetoothState.refresh() }

    Rectangle {
        id: content
        anchors.fill: parent; anchors.topMargin: 6
        radius: Theme.radius; color: Theme.surface
        implicitHeight: Math.min(510, Math.max(155, layout.implicitHeight + 24))
        ColumnLayout {
            id: layout
            anchors.fill: parent; anchors.margins: 12; spacing: 9
            Item { visible: Capabilities.hasWifi
                Layout.fillWidth: true; Layout.preferredHeight: wifiSection.implicitHeight
                ColumnLayout { id: wifiSection; anchors.left: parent.left; anchors.right: parent.right; spacing: 7
                    RowLayout { Layout.fillWidth: true
                        Text { text: "Wi-Fi"; color: Theme.text; font.family: Theme.fontFamily; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: Networking.wifiEnabled ? "ON" : "OFF"; color: Networking.wifiEnabled ? Theme.accent : Theme.muted; font.family: Theme.fontFamily }
                        MouseArea { width: 38; height: 25; onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
                    }
                    ListView { Layout.fillWidth: true; Layout.preferredHeight: Math.min(contentHeight, 170); clip: true; model: root.wifiDevice ? root.wifiDevice.networks : null
                        delegate: Rectangle { required property var modelData; width: ListView.view.width; height: 38; radius: Theme.radius; color: networkMouse.containsMouse ? Theme.surfaceHover : "transparent"
                            RowLayout { anchors.fill: parent; anchors.margins: 8; Text { text: modelData.name; color: modelData.connected ? Theme.accent : Theme.text; font.family: Theme.fontFamily; elide: Text.ElideRight; Layout.fillWidth: true }; Text { text: modelData.connected ? "connected" : Math.round(modelData.signalStrength) + "%"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11 } }
                            MouseArea { id: networkMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { if (modelData.connected) modelData.disconnect(); else if (modelData.known) modelData.connect(); else Quickshell.execDetached(["kitty", "sh", "-lc", "nmcli device wifi connect '" + modelData.name.replace(/'/g, "'\\\"'\\\"'") + "'"]) } }
                        }
                    }
                }
            }
            Rectangle { visible: Capabilities.hasWifi && Capabilities.hasBluetooth; Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }
            Item { visible: Capabilities.hasBluetooth
                Layout.fillWidth: true; Layout.preferredHeight: bluetoothSection.implicitHeight
                ColumnLayout { id: bluetoothSection; anchors.left: parent.left; anchors.right: parent.right; spacing: 7
                    RowLayout { Layout.fillWidth: true
                        Text { text: "Bluetooth"; color: Theme.text; font.family: Theme.fontFamily; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: BluetoothState.enabled ? "ON" : "OFF"; color: BluetoothState.enabled ? Theme.accent : Theme.muted; font.family: Theme.fontFamily }
                        MouseArea { width: 38; height: 25; onClicked: BluetoothState.run("power", BluetoothState.enabled ? "off" : "on") }
                        Text { text: BluetoothState.scanning ? "Stop" : "Scan"; color: Theme.accent; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; onClicked: BluetoothState.scan() } }
                    }
                    Repeater { model: BluetoothState.devices
                        delegate: Rectangle { required property var modelData; Layout.fillWidth: true; height: 38; radius: Theme.radius; color: deviceMouse.containsMouse ? Theme.surfaceHover : "transparent"
                            Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: Theme.text; font.family: Theme.fontFamily; elide: Text.ElideRight }
                            MouseArea { id: deviceMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothState.run("connect", modelData.address) }
                        }
                    }
                    Text { visible: BluetoothState.error.length > 0; text: BluetoothState.error; color: Theme.danger; font.family: Theme.fontFamily; font.pixelSize: 10; wrapMode: Text.Wrap }
                }
            }
        }
    }
}
