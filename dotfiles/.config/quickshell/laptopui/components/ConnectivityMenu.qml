import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme

Item {
    id: root
    property Item anchorItem
    property bool anchoredToPanelEdge: false
    property bool requestedOpen: false
    property var wifiDevice: {
        for (const device of Networking.devices.values) if (device.type === DeviceType.Wifi) return device
        return null
    }
    readonly property bool dualRadio: Capabilities.hasWifi && Capabilities.hasBluetooth
    onRequestedOpenChanged: syncOpenState()

    function syncOpenState() {
        if (requestedOpen) {
            if (wifiDevice) wifiDevice.scannerEnabled = true
            BluetoothState.refresh()
        }
    }

    function connectWifi(network) {
        if (network.connected) {
            network.disconnect()
        } else if (network.known || network.security === WifiSecurityType.Open) {
            network.connect()
        } else {
            wifiPasswordConfirm.network = network
            wifiPasswordConfirm.visible = true
            wifiPasswordInput.forceActiveFocus()
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.requestedOpen || content.opacity > 0
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            focusable: true
            anchors { top: true; bottom: true; left: true; right: true }
            Shortcut { enabled: root.requestedOpen; sequence: "Escape"; onActivated: SettingsState.connectivityOpen = false }
            MouseArea { anchors.fill: parent; onClicked: SettingsState.connectivityOpen = false }

    Rectangle {
        id: content
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.panelPopupCardTop
        anchors.rightMargin: Theme.panelPopupRightInset
        width: root.dualRadio ? 640 : 350
        height: implicitHeight
        // Keep this panel close to the calendar/control-center footprint. A
        // short network list used to make the popup jump noticeably lower.
        radius: Theme.radiusLarge; color: Theme.background
        border.color: Theme.border; border.width: 1
        opacity: root.requestedOpen ? 1 : 0
        scale: root.requestedOpen ? 1 : 0.89
        rotation: root.requestedOpen ? 0 : -1.8
        transformOrigin: Item.TopRight
        implicitHeight: Math.min(410, Math.max(286, layout.implicitHeight + 28))
        focus: root.requestedOpen
        Keys.onEscapePressed: SettingsState.connectivityOpen = false
        MouseArea { anchors.fill: parent }
        Behavior on opacity { NumberAnimation { duration: Theme.animationFast + 30; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.animationNormal + 20; easing.type: Easing.OutBack } }
        Behavior on rotation { NumberAnimation { duration: Theme.animationNormal + 40; easing.type: Easing.OutBack } }
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.requestedOpen ? parent.width * 0.52 : 0
            height: 2
            radius: height / 2
            color: Theme.accent
            opacity: 0.85
            Behavior on width { NumberAnimation { duration: Theme.animationNormal + 80; easing.type: Easing.OutCubic } }
        }
        RowLayout {
            id: layout
            anchors.fill: parent; anchors.margins: 14; spacing: 10
            Item { visible: Capabilities.hasWifi
                Layout.fillWidth: true; Layout.minimumWidth: root.dualRadio ? 280 : 0; Layout.preferredWidth: root.dualRadio ? 300 : 0; Layout.preferredHeight: wifiSection.implicitHeight; Layout.alignment: Qt.AlignTop
                ColumnLayout { id: wifiSection; anchors.left: parent.left; anchors.right: parent.right; spacing: 7
                    RowLayout { Layout.fillWidth: true
                        Text { text: "Wi-Fi"; color: Theme.text; font.family: Theme.fontFamily; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Rectangle { visible: root.wifiDevice && Networking.wifiEnabled; width: 42; height: 22; radius: 11; color: Theme.elevated
                            Text { anchors.centerIn: parent; text: root.wifiDevice && root.wifiDevice.scannerEnabled ? "Stop" : "Scan"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 10 }
                            MouseArea { anchors.fill: parent; onClicked: { if (root.wifiDevice) root.wifiDevice.scannerEnabled = !root.wifiDevice.scannerEnabled } }
                        }
                        Rectangle { width: 42; height: 22; radius: height / 2; color: Networking.wifiEnabled ? Theme.accent : Theme.elevated
                            Rectangle { width: 16; height: 16; radius: width / 2; anchors.verticalCenter: parent.verticalCenter; x: Networking.wifiEnabled ? parent.width - width - 3 : 3; color: Networking.wifiEnabled ? Theme.accentText : Theme.muted
                                Behavior on x { NumberAnimation { duration: Theme.animationFast } }
                            }
                            MouseArea { anchors.fill: parent; onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
                        }
                    }
                    ListView { Layout.fillWidth: true; Layout.preferredHeight: Math.min(contentHeight, 182); clip: true; model: root.wifiDevice ? root.wifiDevice.networks : null
                        delegate: Rectangle { required property var modelData; width: ListView.view.width; height: 38; radius: Theme.radius; color: networkMouse.containsMouse ? Theme.surfaceHover : "transparent"
                            RowLayout { anchors.fill: parent; anchors.margins: 8; Text { text: modelData.name; color: modelData.connected ? Theme.accent : Theme.text; font.family: Theme.fontFamily; elide: Text.ElideRight; Layout.fillWidth: true } Text { text: modelData.connected ? "connected" : Math.round(modelData.signalStrength * 100) + "%"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11 } }
                            MouseArea { id: networkMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.connectWifi(modelData) }
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
                        Rectangle { visible: BluetoothState.enabled; width: 42; height: 22; radius: 11; color: Theme.elevated
                            Text { anchors.centerIn: parent; text: BluetoothState.scanning ? "Stop" : "Scan"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 10 }
                            MouseArea { anchors.fill: parent; onClicked: BluetoothState.scan() }
                        }
                        Rectangle { width: 42; height: 22; radius: height / 2; color: BluetoothState.enabled ? Theme.accent : Theme.elevated
                            Rectangle { width: 16; height: 16; radius: width / 2; anchors.verticalCenter: parent.verticalCenter; x: BluetoothState.enabled ? parent.width - width - 3 : 3; color: BluetoothState.enabled ? Theme.accentText : Theme.muted
                                Behavior on x { NumberAnimation { duration: Theme.animationFast } }
                            }
                            MouseArea { anchors.fill: parent; onClicked: { if (BluetoothState.available) BluetoothState.run("power", BluetoothState.enabled ? "off" : "on"); else BluetoothState.activateService() } }
                        }
                    }
                    Flickable { id: bluetoothList; Layout.fillWidth: true; Layout.preferredHeight: Math.min(bluetoothDeviceColumn.height, 182); clip: true; contentWidth: width; contentHeight: bluetoothDeviceColumn.height
                        Column { id: bluetoothDeviceColumn; width: bluetoothList.width
                            Repeater { model: BluetoothState.devices
                                delegate: Rectangle { required property var modelData; property bool optionsOpen: false; width: bluetoothList.width; height: optionsOpen && modelData.paired ? 70 : 38; radius: Theme.radius; color: deviceMouse.containsMouse ? Theme.surfaceHover : "transparent"
                                    RowLayout { z: 1; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8; height: 22; spacing: 7
                                        Text { text: modelData.name || modelData.deviceName || modelData.address; color: modelData.connected ? Theme.accent : Theme.text; font.family: Theme.fontFamily; elide: Text.ElideRight; Layout.fillWidth: true }
                                        Text { visible: !modelData.paired; text: modelData.pairing ? "pairing" : "new"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10 }
                                        Text { visible: !modelData.paired && modelData.batteryAvailable; text: Math.round(modelData.battery <= 1 ? modelData.battery * 100 : modelData.battery) + "%"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10 }
                                        Rectangle { visible: !modelData.paired && !modelData.pairing; width: 48; height: 25; radius: height / 2; color: Theme.accent
                                            Text { anchors.centerIn: parent; text: "Pair"; color: Theme.accentText; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
                                            MouseArea { anchors.fill: parent; onClicked: { BluetoothState.selectedDevice = modelData; pairConfirm.visible = true } }
                                        }
                                        Text { visible: modelData.pairing || (BluetoothState.pairingInProgress && BluetoothState.pairingAddress === modelData.address); text: "Pairing…"; color: Theme.muted; font.family: Theme.fontFamily }
                                        Rectangle { visible: modelData.paired; width: 82; height: 25; radius: height / 2; color: Theme.accent
                                            Text { anchors.centerIn: parent; text: modelData.connected ? "Disconnect" : "Connect"; color: Theme.accentText; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
                                            MouseArea { anchors.fill: parent; onClicked: BluetoothState.run(modelData.connected ? "disconnect" : "connect", modelData.address) }
                                        }
                                        Rectangle { visible: modelData.paired; width: 26; height: 25; radius: height / 2; color: Theme.elevated
                                            Text { anchors.centerIn: parent; text: "󰒓"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13 }
                                            MouseArea { anchors.fill: parent; onClicked: parent.parent.parent.optionsOpen = !parent.parent.parent.optionsOpen }
                                        }
                                    }
                                    RowLayout { visible: parent.optionsOpen && modelData.paired; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 8; height: 25; spacing: 8
                                        Rectangle { width: 72; height: 25; radius: height / 2; color: Theme.elevated
                                            Text { anchors.centerIn: parent; text: modelData.trusted ? "Untrust" : "Trust"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10 }
                                            MouseArea { anchors.fill: parent; onClicked: BluetoothState.run("trust", modelData.address) }
                                        }
                                        Rectangle { width: 68; height: 25; radius: height / 2; color: Theme.elevated
                                            Text { anchors.centerIn: parent; text: "Forget"; color: Theme.danger; font.family: Theme.fontFamily; font.pixelSize: 10 }
                                            MouseArea { anchors.fill: parent; onClicked: { BluetoothState.run("remove", modelData.address); BluetoothState.selectedDevice = null } }
                                        }
                                    }
                                    MouseArea { id: deviceMouse; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 38; hoverEnabled: true; onClicked: BluetoothState.selectedDevice = modelData }
                                }
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
        Rectangle { id: bluetoothPairPrompt; visible: BluetoothState.pairingPrompt.length > 0; z: 11; anchors.fill: parent; radius: Theme.radius; color: Theme.background; border.color: Theme.accent; border.width: 1
            ColumnLayout { anchors.centerIn: parent; width: parent.width - 34; spacing: 10
                Text { text: "Bluetooth pairing"; color: Theme.text; font.family: Theme.fontFamily; font.bold: true }
                Text { text: BluetoothState.pairingPrompt; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11; wrapMode: Text.Wrap; Layout.fillWidth: true }
                Rectangle { visible: BluetoothState.pairingPromptType === "pin"; Layout.fillWidth: true; height: 34; radius: Theme.radius; color: Theme.elevated
                    TextInput { id: bluetoothPinInput; anchors.fill: parent; anchors.margins: 8; color: Theme.text; font.family: Theme.fontFamily; inputMethodHints: Qt.ImhDigitsOnly; selectByMouse: true; onAccepted: { BluetoothState.answerPairing(text); text = "" } }
                }
                RowLayout { Layout.fillWidth: true
                    Text { text: "Cancel"; color: Theme.muted; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; onClicked: BluetoothState.cancelPairing() } }
                    Item { Layout.fillWidth: true }
                    Text { visible: BluetoothState.pairingPromptType === "confirm"; text: "Reject"; color: Theme.danger; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; onClicked: BluetoothState.answerPairing("no") } }
                    Text { text: BluetoothState.pairingPromptType === "confirm" ? "Confirm" : "Submit"; color: Theme.accent; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; onClicked: { if (BluetoothState.pairingPromptType === "confirm") BluetoothState.answerPairing("yes"); else if (bluetoothPinInput.text.length) { BluetoothState.answerPairing(bluetoothPinInput.text); bluetoothPinInput.text = "" } } } }
                }
            }
            onVisibleChanged: if (visible && BluetoothState.pairingPromptType === "pin") bluetoothPinInput.forceActiveFocus()
        }
        Rectangle { id: wifiPasswordConfirm; property var network: null; visible: false; z: 10; anchors.fill: parent; radius: Theme.radius; color: Theme.background; border.color: Theme.accent; border.width: 1
            function cancel() { wifiPasswordInput.text = ""; network = null; visible = false }
            function connect() {
                if (!network || !wifiPasswordInput.text.length) return
                network.connectWithPsk(wifiPasswordInput.text)
                cancel()
            }
            ColumnLayout { anchors.centerIn: parent; width: parent.width - 34; spacing: 10
                Text { text: "Connect to " + (wifiPasswordConfirm.network ? wifiPasswordConfirm.network.name : "Wi-Fi"); color: Theme.text; font.family: Theme.fontFamily; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: "Wi-Fi password"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10 }
                Rectangle { Layout.fillWidth: true; height: 34; radius: Theme.radius; color: Theme.elevated; border.color: wifiPasswordInput.activeFocus ? Theme.accent : "transparent"; border.width: 1
                    TextInput { id: wifiPasswordInput; anchors.fill: parent; anchors.margins: 8; color: Theme.text; font.family: Theme.fontFamily; echoMode: TextInput.Password; clip: true; selectByMouse: true; onAccepted: wifiPasswordConfirm.connect() }
                }
                RowLayout { Layout.fillWidth: true
                    Text { text: "Cancel"; color: Theme.muted; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; onClicked: wifiPasswordConfirm.cancel() } }
                    Item { Layout.fillWidth: true }
                    Text { text: "Connect"; color: wifiPasswordInput.text.length ? Theme.accent : Theme.muted; font.family: Theme.fontFamily; MouseArea { anchors.fill: parent; enabled: wifiPasswordInput.text.length > 0; onClicked: wifiPasswordConfirm.connect() } }
                }
            }
        }
    }
        }
    }
}
