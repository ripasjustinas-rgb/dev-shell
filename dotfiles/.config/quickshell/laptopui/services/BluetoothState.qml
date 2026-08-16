pragma Singleton

import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import qs.services

Item {
    id: root
    // Some BlueZ setups expose an adapter in the adapters model without
    // selecting defaultAdapter. Treat the first discovered adapter as primary.
    readonly property var adapter: Bluetooth.defaultAdapter || (Bluetooth.adapters.values.length ? Bluetooth.adapters.values[0] : null)
    property bool available: adapter !== null
    // BlueZ reports a state transition before Powered has settled. Derive the
    // UI state from that notified state so panel icons update immediately.
    readonly property int adapterState: adapter ? adapter.state : BluetoothAdapterState.Disabled
    readonly property bool enabled: adapterState === BluetoothAdapterState.Enabled || adapterState === BluetoothAdapterState.Enabling
    property bool scanning: adapter ? adapter.discovering : false
    property string error: ""
    property var devices: adapter ? adapter.devices.values : []
    property var selectedDevice: null
    property string pairingAddress: ""
    property string pairingPrompt: ""
    property string pairingPromptType: ""
    readonly property bool pairingInProgress: pairProcess.running

    // BlueZ changes are delivered through the native Quickshell objects, so
    // callers retain this method only as a stable UI service boundary.
    function refresh() {}
    function scan() {
        if (adapter && adapter.enabled) adapter.discovering = !adapter.discovering
    }
    function activateService() {
        error = "Bluetooth service is not running. Enable it during system setup."
    }
    function startPair(address) {
        if (!adapter || pairProcess.running) return
        error = ""
        pairingAddress = address
        pairingPrompt = ""
        pairingPromptType = ""
        // bluetoothctl registers an interactive BlueZ agent. Its questions are
        // surfaced below instead of using NoInputNoOutput (silent approval).
        pairProcess.exec(["bluetoothctl"])
    }
    function answerPairing(answer) {
        if (!pairProcess.running) return
        pairProcess.write(answer + "\n")
        pairingPrompt = ""
        pairingPromptType = ""
    }
    function cancelPairing() {
        if (pairProcess.running) {
            pairProcess.write("cancel\nquit\n")
            pairProcess.running = false
        }
        pairingPrompt = ""
        pairingPromptType = ""
        pairingAddress = ""
    }
    function handlePairOutput(output) {
        const line = output.replace(/\x1b\[[0-9;]*m/g, "").trim()
        if (!line.length) return
        if (/Pairing successful|Paired:\s*yes/i.test(line)) {
            pairingPrompt = ""
            pairingPromptType = ""
            pairingAddress = ""
            pairProcess.write("quit\n")
            return
        }
        if (/Failed to pair|AuthenticationFailed|AuthenticationCanceled|org\.bluez\.Error/i.test(line)) {
            error = line
            pairingPrompt = ""
            pairingPromptType = ""
            pairingAddress = ""
            pairProcess.write("quit\n")
            return
        }
        const passkey = line.match(/Confirm passkey\s+(\d+)/i)
        if (passkey || /Request confirmation|Authorize service/i.test(line)) {
            pairingPromptType = "confirm"
            pairingPrompt = passkey ? "Does the code " + passkey[1] + " match on the device?" : "Allow this Bluetooth pairing request?"
        } else if (/Enter PIN code|Request PIN code/i.test(line)) {
            pairingPromptType = "pin"
            pairingPrompt = "Enter the PIN shown by the device"
        } else if (/Request passkey|Enter passkey/i.test(line)) {
            pairingPromptType = "pin"
            pairingPrompt = "Enter the passkey shown by the device"
        }
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
        else if (action === "pair") startPair(address)
        else if (action === "trust") device.trusted = !device.trusted
        else if (action === "remove") device.forget()
        if (action === "connect" || action === "disconnect") SettingsState.audioDeviceRefresh += 1
    }

    Process {
        id: pairProcess
        stdinEnabled: true
        stdout: SplitParser { splitMarker: "\n"; onRead: function(data) { root.handlePairOutput(data) } }
        stderr: SplitParser { splitMarker: "\n"; onRead: function(data) { root.handlePairOutput(data) } }
        onStarted: {
            write("agent on\n")
            write("default-agent\n")
            write("pair " + root.pairingAddress + "\n")
        }
        onExited: function(exitCode) {
            if (root.pairingAddress.length && exitCode !== 0 && !root.error.length)
                root.error = "Bluetooth pairing was cancelled or failed."
            root.pairingPrompt = ""
            root.pairingPromptType = ""
            root.pairingAddress = ""
        }
    }

}
