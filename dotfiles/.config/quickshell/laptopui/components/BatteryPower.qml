import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import qs.theme

PanelButton {
    id: batteryButton
    readonly property real rawPercentage: UPower.displayDevice.percentage
    readonly property int percentage: rawPercentage <= 1
        ? Math.round(rawPercentage * 100)
        : Math.round(rawPercentage)
    property string profile: "unavailable"
    visible: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
    implicitWidth: 74
    label: "󰁹 " + percentage + "%"
    labelColor: profile === "performance" ? Theme.danger
        : profile === "power-saver" ? Theme.success
        : profile === "balanced" ? Theme.accent
        : Theme.muted
    tooltip: "Battery and power profile"
    onClicked: Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "toggleControlCenter"])

    Process {
        id: profileQuery
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                if (value.length) batteryButton.profile = value
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: profileQuery.exec(["powerprofilesctl", "get"])
    }
}
