import Quickshell
import QtQuick
import qs.theme

PanelButton {
    id: audioButton
    property string volume: "—"
    property bool muted: false
    label: muted ? "󰖁" : (volume === "—" ? "󰕾" : "󰕾 " + volume)
    labelColor: muted ? Theme.danger : Theme.muted
    tooltip: "Volume and microphone"

    onClicked: audioMenu.visible = !audioMenu.visible

    AudioMenu {
        id: audioMenu
        anchorItem: audioButton
        onSinkStateChanged: {
            audioButton.volume = sinkVolume
            audioButton.muted = sinkMuted
        }
    }
}
