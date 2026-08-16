pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick

Item {
    id: root

    // These values deliberately describe what this host can do, rather than
    // which profile it was installed with. Components must not probe helpers
    // on their own when a capability is false.
    property bool hasBacklight: false
    property bool hasBattery: false
    property bool hasWifi: false
    property bool hasBluetooth: false
    property bool hasAudioSink: false
    property bool hasAudioSource: false
    property bool powerProfilesAvailable: false
    property bool performanceProfileAvailable: false
    property int monitorCount: Quickshell.screens.length
    property bool hasExternalMonitor: monitorCount > 1
    property bool hasBrightnessctl: false
    property bool hasPowerprofilesctl: false
    property bool hasCliphist: false
    property bool hasCava: false
    property bool hasBtop: false
    property var powerProfiles: []
    property string activePowerProfile: ""

    function refresh() {
        probe.exec(["sh", "-c", "test -d /sys/class/backlight && find /sys/class/backlight -mindepth 1 -maxdepth 1 -print -quit | grep -q .; echo backlight:$?; test -d /sys/class/power_supply && find /sys/class/power_supply -maxdepth 2 -name type -exec grep -ql Battery {} \\; -quit; echo battery:$?; for tool in brightnessctl powerprofilesctl cliphist cava btop wpctl; do command -v $tool >/dev/null 2>&1; echo $tool:$?; done"])
        profiles.exec(["sh", "-c", "command -v powerprofilesctl >/dev/null 2>&1 && { powerprofilesctl list; printf '\\n--ACTIVE--\\n'; powerprofilesctl get; } || true"])
    }

    function deviceCapabilities() {
        let wifi = false
        for (const device of Networking.devices.values) {
            if (device.type === DeviceType.Wifi) { wifi = true; break }
        }
        hasWifi = wifi
    }
    function setPowerProfile(profile) {
        if (!powerProfilesAvailable || !powerProfiles.includes(profile)) return
        Quickshell.execDetached(["powerprofilesctl", "set", profile])
        profileRefresh.restart()
    }

    Component.onCompleted: { refresh(); deviceCapabilities() }
    Connections { target: Networking.devices; function onValuesChanged() { root.deviceCapabilities() } }

    Process {
        id: probe
        stdout: StdioCollector { onStreamFinished: {
            const result = {}
            for (const line of text.trim().split("\n")) {
                const pair = line.split(":")
                result[pair[0]] = pair[1] === "0"
            }
            root.hasBacklight = result.backlight
            root.hasBattery = result.battery
            root.hasBrightnessctl = result.brightnessctl
            root.hasPowerprofilesctl = result.powerprofilesctl
            root.hasCliphist = result.cliphist
            root.hasCava = result.cava
            root.hasBtop = result.btop
            root.hasBluetooth = Bluetooth.defaultAdapter !== null
            root.hasAudioSink = result.wpctl
            root.hasAudioSource = result.wpctl
            root.powerProfilesAvailable = result.powerprofilesctl
        } }
    }
    Connections { target: Bluetooth; function onDefaultAdapterChanged() { root.hasBluetooth = Bluetooth.defaultAdapter !== null } }
    Process {
        id: profiles
        stdout: StdioCollector { onStreamFinished: {
            const parts = text.split("--ACTIVE--")
            const names = []
            for (const line of parts[0].split("\n")) {
                const match = line.match(/^\s*\*?\s*([a-z][a-z-]+):/)
                if (match) names.push(match[1])
            }
            root.powerProfiles = names
            root.performanceProfileAvailable = names.includes("performance")
            root.activePowerProfile = parts.length > 1 ? parts[1].trim() : ""
        } }
    }
    Timer { id: profileRefresh; interval: 250; onTriggered: root.refresh() }
}
