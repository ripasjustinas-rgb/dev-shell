import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme

RowLayout {
    spacing: 3

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
        if (Capabilities.hasWifi && !Capabilities.hasBluetooth) return "󰤨"
        if (Capabilities.hasBluetooth && !Capabilities.hasWifi) return "󰂯"
        if (wifiNetwork()) return "󰤨"
        if (connectedBluetoothCount()) return "󰂯"
        return "󰤭"
    }
    function connectivityTooltip() {
        const details = []
        const network = wifiNetwork()
        if (Capabilities.hasWifi) details.push(network ? "Wi-Fi: " + network.name : "Wi-Fi disconnected")
        if (Capabilities.hasBluetooth) details.push(connectedBluetoothCount() ? "Bluetooth: " + connectedBluetoothCount() + " connected" : "Bluetooth disconnected")
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
        anchorItem: connectivityButton
        visible: SettingsState.connectivityOpen
        onVisibleChanged: if (!visible) SettingsState.connectivityOpen = false
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
