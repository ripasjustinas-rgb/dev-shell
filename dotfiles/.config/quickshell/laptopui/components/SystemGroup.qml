import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services

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
        onClicked: connectivityMenu.visible = !connectivityMenu.visible
    }

    ConnectivityMenu {
        id: connectivityMenu
        anchorItem: connectivityButton
    }

    PanelButton {
        label: "󰐥"
        tooltip: "Power menu"
        onClicked: Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "togglePower"])
    }
}
