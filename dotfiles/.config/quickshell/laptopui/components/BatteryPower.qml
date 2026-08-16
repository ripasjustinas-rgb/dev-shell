import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import qs.theme
import qs.services

PanelButton {
    id: batteryButton
    readonly property real rawPercentage: UPower.displayDevice.percentage
    readonly property int percentage: rawPercentage <= 1
        ? Math.round(rawPercentage * 100)
        : Math.round(rawPercentage)
    property string profile: Capabilities.activePowerProfile || "unavailable"
    visible: Capabilities.hasBattery && UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
    implicitWidth: 74
    label: "󰁹 " + percentage + "%"
    labelColor: profile === "performance" ? Theme.danger
        : profile === "power-saver" ? Theme.success
        : profile === "balanced" ? Theme.accent
        : Theme.muted
    tooltip: "Battery and power profile"
    onClicked: Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "toggleControlCenter"])

}
