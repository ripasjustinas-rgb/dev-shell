import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root
    property var mediaPlayers: []
    property var activeMediaPlayer: null
    property var spectrumData: []
    property real bassLevel: 0
    property real shimmerPhase: 0

    function playerPriority(player) {
        if (!player) return 0
        if (player.playbackState === MprisPlaybackState.Playing) return 2
        if (player.playbackState === MprisPlaybackState.Paused) return 1
        return 0
    }

    function registerPlayer(player) {
        if (!player || mediaPlayers.indexOf(player) !== -1) return
        mediaPlayers = mediaPlayers.concat([player])
        refreshActivePlayer()
    }

    function unregisterPlayer(player) {
        mediaPlayers = mediaPlayers.filter(existing => existing !== player)
        refreshActivePlayer()
    }

    function refreshActivePlayer() {
        let best = null
        let priority = 0
        for (const player of mediaPlayers) {
            const nextPriority = playerPriority(player)
            if (nextPriority > priority) {
                best = player
                priority = nextPriority
            }
        }
        activeMediaPlayer = best
    }

    Component.onCompleted: Quickshell.execDetached(["laptopui-visualizer-daemon"])

    Instantiator {
        model: Mpris.players
        delegate: QtObject {
            required property var modelData
            property var player: modelData
            Component.onCompleted: root.registerPlayer(player)
            Component.onDestruction: root.unregisterPlayer(player)
            property Connections playerConnections: Connections {
                target: player
                function onPlaybackStateChanged() { root.refreshActivePlayer() }
                function onTrackChanged() { root.refreshActivePlayer() }
                function onIdentityChanged() { root.refreshActivePlayer() }
            }
        }
    }

    Process {
        id: spectrumProcess
        command: ["laptopui-audio-spectrum"]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw.length) return
                root.spectrumData = raw.split(";").map(value => {
                    const parsed = parseInt(value)
                    return isNaN(parsed) ? 0 : Math.max(0, Math.min(16, parsed))
                })
                let bass = 0
                const count = Math.min(4, root.spectrumData.length)
                for (let index = 0; index < count; ++index) bass += root.spectrumData[index]
                root.bassLevel = count ? bass / count / 16 : 0
            }
        }
    }

    Timer {
        interval: 66
        repeat: true
        running: root.activeMediaPlayer !== null
        onTriggered: if (!spectrumProcess.running) spectrumProcess.running = true
    }

    Timer {
        interval: 40
        repeat: true
        running: true
        onTriggered: root.shimmerPhase += 0.03
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            implicitHeight: Theme.panelHeight
            exclusiveZone: Theme.panelHeight
            color: "transparent"
            WlrLayershell.namespace: "laptopui:panel"

            anchors { top: true; left: true; right: true }

            Rectangle {
                id: glassPanel
                anchors.fill: parent
                anchors.margins: 5
                radius: Theme.radiusLarge
                color: Theme.background
                border.width: 1
                border.color: Theme.glassBorder

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Theme.radiusLarge - 1
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.glassHighlight
                    opacity: 0.42 + 0.10 * Math.sin(root.shimmerPhase)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: Theme.spacing

                    WorkspaceGroup {}
                    Item { Layout.fillWidth: true }
                    SystemGroup {}
                }

                RowLayout {
                    z: 3
                    anchors.centerIn: parent
                    spacing: 7

                    MediaVisualizerWing {
                        active: root.activeMediaPlayer !== null
                        mirrored: true
                        spectrumData: root.spectrumData
                    }

                    ClockWeather {}

                    MediaPill { player: root.activeMediaPlayer }

                    MediaVisualizerWing {
                        active: root.activeMediaPlayer !== null
                        spectrumData: root.spectrumData
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: parent.width * 0.42
                    height: 2
                    radius: 1
                    color: Theme.accent
                    opacity: 0.16 + root.bassLevel * 0.7
                    Behavior on opacity { NumberAnimation { duration: 90 } }
                }
            }
        }
    }
}
