import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Item {
    id: root
    property var mediaPlayers: []
    property var activeMediaPlayer: null
    property var spectrumData: []
    property real bassLevel: 0
    property real bassBaseline: 0
    property int beatCooldownFrames: 0
    property real beatBurst: 0
    property real beatWave: 1
    property real beatWaveEcho: 1
    property real shimmerPhase: 0

    function triggerBeatWave() {
        if (SettingsState.calmMode) return
        beatBurst = 1
        beatBurstDecay.restart()
        primaryBeatWave.restart()
        echoBeatWave.restart()
    }

    function consumeBass(nextBass) {
        if (SettingsState.calmMode) return
        const rise = nextBass - bassBaseline
        const onsetThreshold = Math.max(0.03, bassBaseline * 0.38)
        if (beatCooldownFrames > 0) beatCooldownFrames -= 1
        if (beatCooldownFrames === 0 && nextBass >= 0.09
                && (rise >= onsetThreshold || nextBass >= 0.82)) {
            beatCooldownFrames = 6
            triggerBeatWave()
        }
        bassLevel = nextBass
        bassBaseline = bassBaseline * 0.72 + nextBass * 0.28
    }

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

    Component.onCompleted: Quickshell.execDetached([
        Quickshell.env("HOME") + "/.local/bin/laptopui-visualizer-daemon"
    ])

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
                function onTrackChanged() {
                    root.refreshActivePlayer()
                    if (player === root.activeMediaPlayer) root.triggerBeatWave()
                }
                function onIdentityChanged() { root.refreshActivePlayer() }
            }
        }
    }

    Process {
        id: spectrumProcess
        command: [Quickshell.env("HOME") + "/.local/bin/laptopui-audio-spectrum"]
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
                root.consumeBass(count ? bass / count / 16 : 0)
            }
        }
    }

    NumberAnimation {
        id: primaryBeatWave
        target: root
        property: "beatWave"
        from: 0
        to: 1
        duration: 520
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: echoBeatWave
        PauseAnimation { duration: 85 }
        NumberAnimation {
            target: root
            property: "beatWaveEcho"
            from: 0
            to: 1
            duration: 560
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: beatBurstDecay
        interval: 32
        repeat: true
        onTriggered: {
            root.beatBurst = Math.max(0, root.beatBurst - 0.075)
            if (root.beatBurst <= 0) stop()
        }
    }

    Timer {
        interval: 66
        repeat: true
        running: root.activeMediaPlayer !== null && !SettingsState.calmMode && Capabilities.hasCava
        onTriggered: if (!spectrumProcess.running) spectrumProcess.running = true
    }

    Timer {
        interval: 40
        repeat: true
        running: !SettingsState.calmMode
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
                    opacity: SettingsState.calmMode ? 0.42 : 0.42 + 0.10 * Math.sin(root.shimmerPhase)
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

                Rectangle {
                    anchors.centerIn: centerCluster
                    width: centerCluster.width + 18 + root.bassLevel * 12
                    height: Math.min(glassPanel.height - 6, centerCluster.height + 4)
                    radius: Theme.radiusLarge
                    color: Theme.glow
                    border.width: 1
                    border.color: Theme.accent
                    opacity: root.activeMediaPlayer !== null && !SettingsState.calmMode
                        ? 0.035 + root.bassLevel * 0.24 + root.beatBurst * 0.12 : 0
                    z: 1

                    Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 85; easing.type: Easing.OutCubic } }
                }

                Rectangle {
                    anchors.centerIn: centerCluster
                    width: centerCluster.width + 18 + root.beatWave * 150
                    height: Math.min(glassPanel.height - 5, centerCluster.height + 5)
                    radius: Theme.radiusLarge
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.accent
                    opacity: root.activeMediaPlayer !== null && !SettingsState.calmMode
                        ? Math.pow(1 - root.beatWave, 1.6) * 0.72 : 0
                    z: 2
                }

                Rectangle {
                    anchors.centerIn: centerCluster
                    width: centerCluster.width + 24 + root.beatWaveEcho * 190
                    height: Math.min(glassPanel.height - 7, centerCluster.height + 3)
                    radius: Theme.radiusLarge
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.secondary
                    opacity: root.activeMediaPlayer !== null
                        ? Math.pow(1 - root.beatWaveEcho, 1.8) * 0.46 : 0
                    z: 2
                }

                RowLayout {
                    id: centerCluster
                    z: 3
                    anchors.centerIn: parent
                    spacing: 7

                    MediaVisualizerWing {
                        active: root.activeMediaPlayer !== null && !SettingsState.calmMode
                        mirrored: true
                        spectrumData: root.spectrumData
                        burstLevel: root.beatBurst
                    }

                    ClockWeather {
                        id: clockWeather
                        onClicked: calendarWeather.visible = !calendarWeather.visible
                    }

                    MediaPill { player: root.activeMediaPlayer }

                    MediaVisualizerWing {
                        active: root.activeMediaPlayer !== null && !SettingsState.calmMode
                        spectrumData: root.spectrumData
                        burstLevel: root.beatBurst
                    }
                }

                CalendarWeather {
                    id: calendarWeather
                    anchorItem: clockWeather
                    location: clockWeather.location
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: parent.width * 0.42
                    height: 2
                    radius: 1
                    color: Theme.accent
                    opacity: SettingsState.calmMode ? 0.16 : 0.16 + root.bassLevel * 0.7
                    Behavior on opacity { NumberAnimation { duration: 90 } }
                }
            }
        }
    }
}
