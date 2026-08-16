pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property bool dnd: false
    property bool calmMode: false
    property bool reducedMotion: false
    // Transient overlay coordination; persistent preferences remain the only
    // values written to disk by this service.
    property bool connectivityOpen: false
    property int audioDeviceRefresh: 0
    property string statePath: Quickshell.env("HOME") + "/.local/state/laptopui/settings"

    function save() {
        writer.exec(["sh", "-c", "mkdir -p \"$HOME/.local/state/laptopui\" && printf '%s\\n' \"dnd=" + (dnd ? "1" : "0") + "\" \"calmMode=" + (calmMode ? "1" : "0") + "\" \"reducedMotion=" + (reducedMotion ? "1" : "0") + "\" > \"$HOME/.local/state/laptopui/settings\""])
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
            if (pair[0] === "reducedMotion") root.reducedMotion = pair[1] === "1"
        }
    } } }
}
