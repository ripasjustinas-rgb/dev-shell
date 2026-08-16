pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

QtObject {
    id: root
    property bool available: Capabilities.hasBluetooth
    property bool enabled: false
    property bool scanning: false
    property string error: ""
    property var devices: []

    function refresh() {
        if (!available) return
        stateQuery.exec(["sh", "-c", "bluetoothctl show 2>/dev/null; printf '\\n--DEVICES--\\n'; bluetoothctl devices 2>/dev/null"])
    }
    function scan() { if (!available) return; scanning = !scanning; command.exec(["bluetoothctl", "scan", scanning ? "on" : "off"]); refreshTimer.restart() }
    function run(action, address) { if (!available) return; error = ""; command.exec(["bluetoothctl", action, address]); refreshTimer.restart() }
    Component.onCompleted: refresh()
    Timer { id: refreshTimer; interval: 700; onTriggered: root.refresh() }
    Process { id: command; stderr: StdioCollector { onStreamFinished: { if (text.trim()) root.error = text.trim() } } }
    Process { id: stateQuery; stdout: StdioCollector { onStreamFinished: {
        const parts = text.split("--DEVICES--")
        root.enabled = /Powered:\s*yes/i.test(parts[0])
        root.devices = parts.length < 2 ? [] : parts[1].trim().split("\n").filter(line => line.startsWith("Device ")).map(line => {
            const bits = line.split(" "); return { address: bits[1], name: bits.slice(2).join(" ") }
        })
    } } }
}
