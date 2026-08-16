import QtQuick
import qs.theme
import qs.services

PanelButton {
    id: root
    visible: Capabilities.powerProfilesAvailable
    property string profile: Capabilities.activePowerProfile || "unavailable"
    property bool performanceAvailable: Capabilities.performanceProfileAvailable
    label: profile === "performance" ? "󰓅" : profile === "power-saver" ? "󰾆" : "󰾅"
    labelColor: profile === "performance" ? Theme.danger
        : profile === "power-saver" ? Theme.success
        : profile === "balanced" ? Theme.accent : Theme.muted
    tooltip: "Power profile: " + profile

    onClicked: {
        const next = performanceAvailable
            ? (profile === "performance" ? "balanced" : "performance")
            : (profile === "power-saver" ? "balanced" : "power-saver")
        Capabilities.setPowerProfile(next)
    }
}
