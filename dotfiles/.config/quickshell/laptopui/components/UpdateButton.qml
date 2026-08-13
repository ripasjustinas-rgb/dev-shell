import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

Rectangle {
    id: root
    property string count: "…"
    implicitWidth: count === "0" ? 30 : 40
    implicitHeight: 26
    radius: Theme.radius
    color: mouse.containsMouse ? Theme.surfaceHover : Theme.surface

    function refresh() {
        updates.exec([Quickshell.env("HOME") + "/.local/bin/laptopui-update-count"])
    }

    Text {
        anchors.centerIn: parent
        text: root.count === "0" ? "󰚰" : "󰚰 " + root.count
        color: root.count === "0" ? Theme.muted : Theme.warningColor
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/laptopui-update"])
    }

    Process {
        id: updates
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                root.count = value.length ? value : "—"
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
