import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme

RowLayout {
    id: root
    spacing: 3
    property Item connectivityAnchorItem: null

    function wifiNetwork() {
        for (const device of Networking.devices.values) {
            if (device.type !== DeviceType.Wifi) continue
            for (const network of device.networks.values) if (network.connected) return network
        }
        return null
    }
    function connectedBluetoothCount() {
        return BluetoothState.devices.filter(device => device.connected).length
    }
    function connectivityIcon() {
        const wifiIcon = Networking.wifiEnabled ? "󰤨" : "󰤮"
        // Read adapterState directly as well as enabled: this keeps the label
        // bound to BlueZ's transition notification, not merely the popup UI.
        const bluetoothIcon = BluetoothState.available && (BluetoothState.adapterState === BluetoothAdapterState.Enabled || BluetoothState.adapterState === BluetoothAdapterState.Enabling) ? "󰂯" : "󰂲"
        if (Capabilities.hasWifi && !Capabilities.hasBluetooth) return wifiIcon
        if (Capabilities.hasBluetooth && !Capabilities.hasWifi)
            return bluetoothIcon
        if (Capabilities.hasWifi && Capabilities.hasBluetooth) {
            return wifiIcon + " " + bluetoothIcon
        }
        return "󰤭"
    }
    function connectivityTooltip() {
        const details = []
        const network = wifiNetwork()
        if (Capabilities.hasWifi) details.push(!Networking.wifiEnabled ? "Wi-Fi off" : (network ? "Wi-Fi: " + network.name : "Wi-Fi on, disconnected"))
        if (Capabilities.hasBluetooth) details.push(!BluetoothState.available || !BluetoothState.enabled ? "Bluetooth off" : (connectedBluetoothCount() ? "Bluetooth: " + connectedBluetoothCount() + " connected" : "Bluetooth on, disconnected"))
        return details.join(" · ")
    }

    SystemStats {}

    Tray {}

    AudioControl {}

    KeyboardLayout {}

    BatteryPower { id: batteryControl }

    PerformanceProfile {}

    PanelButton {
        id: connectivityButton
        visible: Capabilities.hasWifi || Capabilities.hasBluetooth
        label: connectivityIcon()
        tooltip: connectivityTooltip()
        onClicked: SettingsState.connectivityOpen = !SettingsState.connectivityOpen
    }

    ConnectivityMenu {
        id: connectivityMenu
        anchorItem: root.connectivityAnchorItem || connectivityButton
        anchoredToPanelEdge: root.connectivityAnchorItem !== null
        requestedOpen: SettingsState.connectivityOpen
    }

    PanelButton {
        label: NotificationState.unreadCount > 0 ? "󰂚 " + NotificationState.unreadCount : "󰂚"
        labelColor: NotificationState.unreadCount > 0 ? Theme.accent : Theme.muted
        tooltip: NotificationState.unreadCount > 0 ? NotificationState.unreadCount + " unread notifications" : "Notifications"
        onClicked: Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "toggleNotifications"])
    }

    PanelButton {
        label: "󰐥"
        tooltip: "Power menu"
        onClicked: Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "togglePower"])
    }
}
