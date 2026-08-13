import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.theme

PopupWindow {
    id: root
    property Item anchorItem
    property string sinkVolume: "—"
    property string sourceVolume: "—"
    property bool sinkMuted: false
    property bool sourceMuted: false
    signal sinkStateChanged()

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
    implicitWidth: 248
    implicitHeight: content.implicitHeight
    visible: false
    color: "transparent"
    grabFocus: true

    function parseVolume(text, microphone) {
        const match = text.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/)
        const volume = match ? Math.round(Number(match[1]) * 100) + "%" : "—"
        const muted = match ? Boolean(match[2]) : false
        if (microphone) {
            sourceVolume = volume
            sourceMuted = muted
        } else {
            sinkVolume = volume
            sinkMuted = muted
            sinkStateChanged()
        }
    }

    function refresh() {
        sinkQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
        sourceQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"])
    }

    function change(target, amount) {
        Quickshell.execDetached(["wpctl", "set-volume", target, amount])
        refreshDelay.restart()
    }

    function toggleMute(target) {
        Quickshell.execDetached(["wpctl", "set-mute", target, "toggle"])
        refreshDelay.restart()
    }

    onVisibleChanged: if (visible) refresh()

    Process {
        id: sinkQuery
        stdout: StdioCollector { onStreamFinished: root.parseVolume(text, false) }
    }
    Process {
        id: sourceQuery
        stdout: StdioCollector { onStreamFinished: root.parseVolume(text, true) }
    }

    Timer {
        id: refreshDelay
        interval: 180
        onTriggered: root.refresh()
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Rectangle {
        id: content
        anchors.fill: parent
        anchors.topMargin: 6
        radius: Theme.radius
        color: Theme.surface
        implicitHeight: 130

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text { text: "Audio"; color: Theme.text; font.family: Theme.fontFamily; font.bold: true }

            AudioRow {
                icon: root.sinkMuted ? "󰖁" : "󰕾"
                title: "Output"
                value: root.sinkVolume
                muted: root.sinkMuted
                onDecrease: root.change("@DEFAULT_AUDIO_SINK@", "2%-")
                onIncrease: root.change("@DEFAULT_AUDIO_SINK@", "2%+")
                onMute: root.toggleMute("@DEFAULT_AUDIO_SINK@")
            }

            AudioRow {
                icon: root.sourceMuted ? "󰍭" : "󰍬"
                title: "Microphone"
                value: root.sourceVolume
                muted: root.sourceMuted
                onDecrease: root.change("@DEFAULT_AUDIO_SOURCE@", "2%-")
                onIncrease: root.change("@DEFAULT_AUDIO_SOURCE@", "2%+")
                onMute: root.toggleMute("@DEFAULT_AUDIO_SOURCE@")
            }
        }
    }
}
