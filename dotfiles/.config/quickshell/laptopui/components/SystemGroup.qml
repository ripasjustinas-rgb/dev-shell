import Quickshell
import QtQuick
import QtQuick.Layouts

RowLayout {
    spacing: 3

    SystemStats {}

    Tray {}

    AudioControl {}

    KeyboardLayout {}

    BatteryPower { id: batteryControl }

    PerformanceProfile {}

    PanelButton {
        id: wifiButton
        label: "󰤨"
        tooltip: "Wi-Fi"
        onClicked: wifiMenu.visible = !wifiMenu.visible
    }

    WifiMenu {
        id: wifiMenu
        anchorItem: wifiButton
    }

    PanelButton {
        label: "󰐥"
        tooltip: "Power menu"
        onClicked: Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "togglePower"])
    }
}
