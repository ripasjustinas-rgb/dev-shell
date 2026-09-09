pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Item {
    id: root
    property bool dnd: false
    property bool calmMode: false
    property bool reducedMotion: false
    // Transient overlay coordination; persistent preferences remain the only
    // values written to disk by this service.
    readonly property string focusedScreen: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : (Quickshell.screens.length ? Quickshell.screens[0].name : "")
    property bool connectivityOpen: false
    property bool controlOpen: false
    property string mediaScreen: ""
    signal overlayOpened(string name)
    onConnectivityOpenChanged: if (connectivityOpen) { mediaScreen = ""; overlayOpened("connectivity") }
    onMediaScreenChanged: if (mediaScreen.length) { connectivityOpen = false; overlayOpened("media") }
    property bool focusMode: false
    property bool previousDnd: false
    property bool previousCalm: false
    function toggleFocusMode() {
        if (!focusMode) {
            previousDnd = dnd; previousCalm = calmMode
            focusMode = true; dnd = true; calmMode = true
        } else {
            focusMode = false; dnd = previousDnd; calmMode = previousCalm
        }
        save()
    }
    property int audioDeviceRefresh: 0
    property string statePath: Quickshell.env("HOME") + "/.local/state/laptopui/settings"

    function save() { saveTimer.restart() }
    Timer { id: saveTimer; interval: 100; onTriggered: root.writeSettings() }
    function writeSettings() {
        writer.exec(["sh", "-c", "mkdir -p \"$HOME/.local/state/laptopui\" && printf '%s\\n' \"dnd=" + (dnd ? "1" : "0") + "\" \"calmMode=" + (calmMode ? "1" : "0") + "\" \"reducedMotion=" + (reducedMotion ? "1" : "0") + "\" \"focusMode=" + (focusMode ? "1" : "0") + "\" \"previousDnd=" + (previousDnd ? "1" : "0") + "\" \"previousCalm=" + (previousCalm ? "1" : "0") + "\" > \"$HOME/.local/state/laptopui/settings\""])
    }
    function toggleDnd() { dnd = !dnd; save() }
    function toggleCalmMode() { calmMode = !calmMode; save() }
    Component.onCompleted: reader.exec(["sh", "-c", "test -r \"$HOME/.local/state/laptopui/settings\" && cat \"$HOME/.local/state/laptopui/settings\" || true"])
    Process { id: writer }
    Process { id: reader; stdout: StdioCollector { onStreamFinished: {
        for (const line of text.split("\n")) {
            const pair = line.split("=")
            if (pair[0] === "dnd") root.dnd = pair[1] === "1"
            if (pair[0] === "calmMode") root.calmMode = pair[1] === "1"
            if (pair[0] === "focusMode") root.focusMode = pair[1] === "1"
            if (pair[0] === "previousDnd") root.previousDnd = pair[1] === "1"
            if (pair[0] === "previousCalm") root.previousCalm = pair[1] === "1"
            if (pair[0] === "reducedMotion") root.reducedMotion = pair[1] === "1"
        }
    } } }
}
