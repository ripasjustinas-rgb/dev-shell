pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property bool enabled: false
    property string monitor: ""
    property int slotWidth: 0
    property bool profileLoaded: false
    readonly property bool available: Capabilities.hasWpets
    readonly property bool shouldRun: profileLoaded && enabled && available
        && !SettingsState.calmMode && !SettingsState.reducedMotion
    property string profilePath: Quickshell.env("HOME") + "/.local/state/laptopui/vpet-profile.env"

    function visibleOn(screenName) {
        return enabled && available && monitor.length > 0 && monitor === screenName
    }

    function syncService() {
        if (!profileLoaded) return
        serviceControl.exec(["systemctl", "--user", shouldRun ? "start" : "stop", "laptopui-vpet.service"])
    }

    Component.onCompleted: profileReader.exec(["sh", "-c", "test -r \"$HOME/.local/state/laptopui/vpet-profile.env\" && cat \"$HOME/.local/state/laptopui/vpet-profile.env\" || true"])
    onShouldRunChanged: syncService()

    Process { id: serviceControl }
    Process {
        id: profileReader
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const separator = line.indexOf("=")
                    if (separator < 1) continue
                    const key = line.slice(0, separator)
                    const value = line.slice(separator + 1)
                    if (key === "VPET_ENABLED") root.enabled = value === "1"
                    if (key === "VPET_MONITOR") root.monitor = value
                    if (key === "VPET_SLOT_WIDTH") {
                        const width = parseInt(value)
                        root.slotWidth = isNaN(width) ? 0 : Math.max(0, width)
                    }
                }
                root.profileLoaded = true
                root.syncService()
            }
        }
    }
}
