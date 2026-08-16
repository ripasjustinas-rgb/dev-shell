pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

Item {
    id: root
    property bool available: Capabilities.hasBluetooth
    property bool enabled: false
    property bool scanning: false
    property string error: ""
    property var devices: []
    property var selectedDevice: null

    function refresh() {
        if (!available) return
        stateQuery.exec(["sh", "-c", "bluetoothctl show 2>/dev/null; printf '\\n--DEVICES--\\n'; bluetoothctl devices 2>/dev/null | while IFS= read -r line; do address=$(printf '%s' \"$line\" | awk '{print $2}'); name=$(printf '%s' \"$line\" | cut -d' ' -f3-); [ -n \"$address\" ] || continue; info=$(bluetoothctl info \"$address\" 2>/dev/null); connected=$(printf '%s\\n' \"$info\" | sed -n 's/.*Connected: //p' | head -n1); paired=$(printf '%s\\n' \"$info\" | sed -n 's/.*Paired: //p' | head -n1); trusted=$(printf '%s\\n' \"$info\" | sed -n 's/.*Trusted: //p' | head -n1); battery=$(printf '%s\\n' \"$info\" | sed -n 's/.*Battery Percentage:.*(\\([0-9][0-9]*\\)).*/\\1/p' | head -n1); icon=$(printf '%s\\n' \"$info\" | sed -n 's/.*Icon: //p' | head -n1); printf '%s|%s|%s|%s|%s|%s|%s\\n' \"$address\" \"$name\" \"$connected\" \"$paired\" \"$trusted\" \"$battery\" \"$icon\"; done"])
    }
    function scan() { if (!available) return; scanning = !scanning; command.exec(["bluetoothctl", "scan", scanning ? "on" : "off"]); refreshTimer.restart() }
    function run(action, address) {
        if (!available) return
        error = ""
        command.exec(["bluetoothctl", action, address])
        if (action === "connect" || action === "disconnect") SettingsState.audioDeviceRefresh += 1
        refreshTimer.restart()
    }
    Component.onCompleted: refresh()
    Timer { id: refreshTimer; interval: 700; onTriggered: root.refresh() }
    Process { id: command; stderr: StdioCollector { onStreamFinished: { if (text.trim()) root.error = text.trim() } } }
    Process { id: stateQuery; stdout: StdioCollector { onStreamFinished: {
        const parts = text.split("--DEVICES--")
        root.enabled = /Powered:\s*yes/i.test(parts[0])
        root.devices = parts.length < 2 ? [] : parts[1].trim().split("\n").filter(line => line.length).map(line => {
            const bits = line.split("|")
            return { address: bits[0], name: bits[1], connected: bits[2] === "yes", paired: bits[3] === "yes", trusted: bits[4] === "yes", battery: bits[5], type: bits[6] }
        })
        if (root.selectedDevice) root.selectedDevice = root.devices.find(device => device.address === root.selectedDevice.address) || null
    } } }
}
