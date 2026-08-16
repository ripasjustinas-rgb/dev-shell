import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

PanelButton {
    id: audioButton
    property string volume: "—"
    property bool muted: false
    label: muted ? "󰖁" : (volume === "—" ? "󰕾" : "󰕾 " + volume)
    labelColor: muted ? Theme.danger : Theme.muted
    tooltip: "Volume and microphone"

    function refresh() {
        sinkQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
    }

    onClicked: Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "toggleControlCenter"])

    Process {
        id: sinkQuery
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/)
                audioButton.volume = match ? Math.round(Number(match[1]) * 100) + "%" : "—"
                audioButton.muted = match ? Boolean(match[2]) : false
            }
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: audioButton.refresh()
    }
}
