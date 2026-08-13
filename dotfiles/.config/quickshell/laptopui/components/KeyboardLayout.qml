import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

PanelButton {
    id: keyboardButton
    property string layout: "--"
    label: layout
    tooltip: "Switch keyboard layout"
    labelColor: Theme.accent

    function refresh() {
        keyboardQuery.exec(["hyprctl", "devices", "-j"])
    }

    onClicked: {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "current", "next"])
        refreshTimer.restart()
    }

    Process {
        id: keyboardQuery
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboards = JSON.parse(text).keyboards
                    const main = keyboards.find(device => device.main) || keyboards[0]
                    if (!main) return
                    const names = main.layout.split(",")
                    keyboardButton.layout = (names[main.active_layout_index] || main.active_keymap || "--").toUpperCase()
                } catch (error) {
                    keyboardButton.layout = "--"
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 1000
        onTriggered: keyboardButton.refresh()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: keyboardButton.refresh()
    }
}
