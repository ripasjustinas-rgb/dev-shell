pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import qs.services

Item {
    id: root
    readonly property var adapter: Bluetooth.defaultAdapter
    property bool available: adapter !== null
    property bool enabled: adapter ? adapter.enabled : false
    property bool scanning: adapter ? adapter.discovering : false
    property bool activationPending: false
    property string error: ""
    property var devices: adapter ? adapter.devices.values : []
    property var selectedDevice: null

    // BlueZ changes are delivered through the native Quickshell objects, so
    // callers retain this method only as a stable UI service boundary.
    function refresh() {}
    function scan() {
        if (adapter && adapter.enabled) adapter.discovering = !adapter.discovering
    }
    function activateService() {
        if (serviceStart.running) return
        error = ""
        activationPending = true
        // pkexec presents a Polkit dialog in the running graphical session.
        // Once BlueZ starts, Bluetooth.defaultAdapter updates automatically.
        serviceStart.exec(["pkexec", "systemctl", "start", "bluetooth.service"])
    }
    function run(action, address) {
        if (!adapter) return
        error = ""
        if (action === "power") {
            adapter.enabled = address === "on"
            return
        }
        const device = devices.find(candidate => candidate.address === address)
        if (!device) return
        if (action === "connect") device.connect()
        else if (action === "disconnect") device.disconnect()
        else if (action === "pair") device.pair()
        else if (action === "trust") device.trusted = !device.trusted
        else if (action === "remove") device.forget()
        if (action === "connect" || action === "disconnect") SettingsState.audioDeviceRefresh += 1
    }

    Process {
        id: serviceStart
        stderr: StdioCollector { onStreamFinished: { if (text.trim()) root.error = text.trim() } }
        onExited: function(exitCode) {
            root.activationPending = false
            if (exitCode !== 0 && !root.error.length)
                root.error = "Bluetooth service could not be started."
        }
    }
}
