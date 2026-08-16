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
    readonly property bool dualRadio: Capabilities.hasWifi && Capabilities.hasBluetooth
    implicitWidth: dualRadio ? 640 : 350
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
        RowLayout {
            id: layout
            anchors.fill: parent; anchors.margins: 12; spacing: 9
            Item { visible: Capabilities.hasWifi
                Layout.fillWidth: true; Layout.minimumWidth: root.dualRadio ? 280 : 0; Layout.preferredWidth: root.dualRadio ? 300 : 0; Layout.preferredHeight: wifiSection.implicitHeight; Layout.alignment: Qt.AlignTop
                ColumnLayout { id: wifiSection; anchors.left: parent.left; anchors.right: parent.right; spacing: 7
                    RowLayout { Layout.fillWidth: true
                        Text { text: "Wi-Fi"; color: Theme.text; font.family: Theme.fontFamily; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Rectangle { width: 42; height: 22; radius: height / 2; color: Networking.wifiEnabled ? Theme.accent : Theme.elevated
                            Rectangle { width: 16; height: 16; radius: width / 2; anchors.verticalCenter: parent.verticalCenter; x: Networking.wifiEnabled ? parent.width - width - 3 : 3; color: Networking.wifiEnabled ? Theme.accentText : Theme.muted
                                Behavior on x { NumberAnimation { duration: Theme.animationFast } }
                            }
                            MouseArea { anchors.fill: parent; onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
                        }
                    }
                    ListView { Layout.fillWidth: true; Layout.preferredHeight: Math.min(contentHeight, 170); clip: true; model: root.wifiDevice ? root.wifiDevice.networks : null
                        delegate: Rectangle { required property var modelData; width: ListView.view.width; height: 38; radius: Theme.radius; color: networkMouse.containsMouse ? Theme.surfaceHover : "transparent"
                            RowLayout { anchors.fill: parent; anchors.margins: 8; Text { text: modelData.name; color: modelData.connected ? Theme.accent : Theme.text; font.family: Theme.fontFamily; elide: Text.ElideRight; Layout.fillWidth: true } Text { text: modelData.connected ? "connected" : Math.round(modelData.signalStrength) + "%"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11 } }
                            MouseArea { id: networkMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { if (modelData.connected) modelData.disconnect(); else if (modelData.known) modelData.connect(); else Quickshell.execDetached(["kitty", "sh", "-lc", "nmcli device wifi connect '" + modelData.name.replace(/'/g, "'\\\"'\\\"'") + "'"]) } }
                        }
                    }
                }
            }
            Rectangle { visible: Capabilities.hasWifi && Capabilities.hasBluetooth; Layout.fillHeight: true; width: 1; color: Theme.surfaceHover }
            Item { visible: Capabilities.hasBluetooth
                Layout.fillWidth: true; Layout.minimumWidth: root.dualRadio ? 280 : 0; Layout.preferredWidth: root.dualRadio ? 300 : 0; Layout.preferredHeight: bluetoothSection.implicitHeight; Layout.alignment: Qt.AlignTop
                ColumnLayout { id: bluetoothSection; anchors.left: parent.left; anchors.right: parent.right; spacing: 7
                    RowLayout { Layout.fillWidth: true
                        Text { text: "Bluetooth"; color: Theme.text; font.family: Theme.fontFamily; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { visible: !BluetoothState.available; text: "Inactive"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10 }
                        Rectangle { width: 42; height: 22; radius: height / 2; color: BluetoothState.enabled ? Theme.accent : Theme.elevated
                            Rectangle { width: 16; height: 16; radius: width / 2; anchors.verticalCenter: parent.verticalCenter; x: BluetoothState.enabled ? parent.width - width - 3 : 3; color: BluetoothState.enabled ? Theme.accentText : Theme.muted
                                Behavior on x { NumberAnimation { duration: Theme.animationFast } }
                            }
                            MouseArea { anchors.fill: parent; onClicked: { if (BluetoothState.available) BluetoothState.run("power", BluetoothState.enabled ? "off" : "on"); else BluetoothState.activateService() } }
                        }
                        Text { visible: BluetoothState.enabled; text: BluetoothState.scanning ? "Stop" : "Scan"; color: Theme.accent; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; onClicked: BluetoothState.scan() } }
                    }
                    Repeater { model: BluetoothState.devices
                        delegate: Rectangle { required property var modelData; Layout.fillWidth: true; height: 38; radius: Theme.radius; color: deviceMouse.containsMouse ? Theme.surfaceHover : "transparent"
                            RowLayout { anchors.fill: parent; anchors.margins: 8; Text { text: modelData.name || modelData.deviceName || modelData.address; color: modelData.connected ? Theme.accent : Theme.text; font.family: Theme.fontFamily; elide: Text.ElideRight; Layout.fillWidth: true } Text { text: modelData.pairing ? "pairing" : (modelData.connected ? "connected" : (modelData.paired ? "paired" : "new")); color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10 } Text { visible: modelData.batteryAvailable; text: Math.round(modelData.battery <= 1 ? modelData.battery * 100 : modelData.battery) + "%"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10 } }
                            MouseArea { id: deviceMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothState.selectedDevice = modelData }
                        }
                    }
                    Rectangle { visible: BluetoothState.selectedDevice !== null; Layout.fillWidth: true; height: 72; radius: Theme.radius; color: Theme.elevated
                        ColumnLayout { anchors.fill: parent; anchors.margins: 8; spacing: 4
                            Text { text: BluetoothState.selectedDevice ? (BluetoothState.selectedDevice.name || BluetoothState.selectedDevice.deviceName || BluetoothState.selectedDevice.address) : ""; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11 }
                            RowLayout { Layout.fillWidth: true; spacing: 8
                                Text { visible: BluetoothState.selectedDevice && !BluetoothState.selectedDevice.paired && !BluetoothState.selectedDevice.pairing; text: "Pair"; color: Theme.accent; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; onClicked: pairConfirm.visible = true } }
                                Text { visible: BluetoothState.selectedDevice && BluetoothState.selectedDevice.pairing; text: "Pairing…"; color: Theme.muted; font.family: Theme.fontFamily }
                                Text { visible: BluetoothState.selectedDevice && BluetoothState.selectedDevice.paired; text: BluetoothState.selectedDevice && BluetoothState.selectedDevice.paired ? (BluetoothState.selectedDevice.connected ? "Disconnect" : "Connect") : ""; color: Theme.accent; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; onClicked: BluetoothState.run(BluetoothState.selectedDevice.connected ? "disconnect" : "connect", BluetoothState.selectedDevice.address) } }
                                Text { visible: BluetoothState.selectedDevice && BluetoothState.selectedDevice.paired; text: BluetoothState.selectedDevice && BluetoothState.selectedDevice.paired ? (BluetoothState.selectedDevice.trusted ? "Untrust" : "Trust") : ""; color: Theme.accent; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; onClicked: BluetoothState.run("trust", BluetoothState.selectedDevice.address) } }
                                Text { visible: BluetoothState.selectedDevice && BluetoothState.selectedDevice.paired; text: "Forget"; color: Theme.danger; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; onClicked: { BluetoothState.run("remove", BluetoothState.selectedDevice.address); BluetoothState.selectedDevice = null } } }
                            }
                        }
                    }
                    Text { visible: BluetoothState.error.length > 0; text: BluetoothState.error; color: Theme.danger; font.family: Theme.fontFamily; font.pixelSize: 10; wrapMode: Text.Wrap }
                }
            }
        }
        Rectangle { id: pairConfirm; visible: false; z: 10; anchors.fill: parent; radius: Theme.radius; color: Theme.background; border.color: Theme.accent; border.width: 1
            ColumnLayout { anchors.centerIn: parent; width: parent.width - 34; spacing: 10
                Text { text: "Pair Bluetooth device?"; color: Theme.text; font.family: Theme.fontFamily; font.bold: true }
                Text { text: "Confirm the PIN shown by the device or system pairing agent. Pairing is never silently authorized."; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10; wrapMode: Text.Wrap; Layout.fillWidth: true }
                RowLayout { Text { text: "Cancel"; color: Theme.muted; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; onClicked: pairConfirm.visible = false } } Item { Layout.fillWidth: true } Text { text: "Pair"; color: Theme.accent; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; onClicked: { BluetoothState.run("pair", BluetoothState.selectedDevice.address); pairConfirm.visible = false } } } }
            }
        }
    }
}
