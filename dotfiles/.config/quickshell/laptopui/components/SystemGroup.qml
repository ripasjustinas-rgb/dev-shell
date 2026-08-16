import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme

RowLayout {
    spacing: 3

    SystemStats {}

    Tray {}

    AudioControl {}

    KeyboardLayout {}

    BatteryPower { id: batteryControl }

    PerformanceProfile {}

    PanelButton {
        id: connectivityButton
        visible: Capabilities.hasWifi || Capabilities.hasBluetooth
        label: Capabilities.hasWifi ? "󰤨" : "󰂯"
        tooltip: Capabilities.hasWifi && Capabilities.hasBluetooth ? "Connectivity" : (Capabilities.hasWifi ? "Wi-Fi" : "Bluetooth")
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
