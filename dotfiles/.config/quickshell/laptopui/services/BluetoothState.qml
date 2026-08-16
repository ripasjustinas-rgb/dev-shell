pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick
import qs.services

Item {
    id: root
    readonly property var adapter: Bluetooth.defaultAdapter
    property bool available: adapter !== null
    property bool enabled: adapter ? adapter.enabled : false
    property bool scanning: adapter ? adapter.discovering : false
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
        error = ""
        // systemctl delegates authorization to the active desktop polkit agent.
        // Once BlueZ starts, Bluetooth.defaultAdapter updates automatically.
        Quickshell.execDetached(["systemctl", "start", "bluetooth.service"])
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
}
