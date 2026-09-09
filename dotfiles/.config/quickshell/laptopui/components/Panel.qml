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
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (SettingsState.mediaScreen.length && !Quickshell.screens.some(screen => screen.name === SettingsState.mediaScreen)) SettingsState.mediaScreen = ""
        }
    }
    property var mediaPlayers: []
    property var activeMediaPlayer: null
    property var preferredPlayer: null
    readonly property bool visualizerActive: activeMediaPlayer !== null && activeMediaPlayer.playbackState === MprisPlaybackState.Playing && !SettingsState.calmMode && !SettingsState.reducedMotion && Capabilities.hasCava
    onVisualizerActiveChanged: if (!visualizerActive) {
        spectrumProcess.running = false
        spectrumData = []; bassLevel = 0; beatBurst = 0
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/laptopui-visualizer-daemon", "--stop"])
    }
    property var spectrumData: []
    property real bassLevel: 0
    property real bassBaseline: 0
    property int beatCooldownFrames: 0
    property real beatBurst: 0
    property real beatWave: 1
    property real beatWaveEcho: 1
    property real shimmerPhase: 0

    IpcHandler {
        target: "media"
        function status(): string { return JSON.stringify({active: root.visualizerActive, sampling: spectrumProcess.running, samples: root.spectrumData, bass: root.bassLevel, calm: SettingsState.calmMode, reducedMotion: SettingsState.reducedMotion}) }
    }

    function triggerBeatWave() {
        if (SettingsState.calmMode || SettingsState.reducedMotion) return
        beatBurst = 1
        beatBurstDecay.restart()
        primaryBeatWave.restart()
        echoBeatWave.restart()
    }

    function consumeBass(nextBass) {
        if (SettingsState.calmMode || SettingsState.reducedMotion) return
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
        activeMediaPlayer = preferredPlayer && mediaPlayers.indexOf(preferredPlayer) !== -1 ? preferredPlayer : best
        if (!activeMediaPlayer) SettingsState.mediaScreen = ""
    }

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
                const raw = text.trim().replace(/;+$/, "")
                if (!raw.length) return
                root.spectrumData = raw.split(";").map(value => {
                    const parsed = parseInt(value)
                    return isNaN(parsed) ? 0 : Math.max(0, Math.min(16, parsed))
                })
                // RMS across the low-frequency band keeps kick/bass energy
                // visible even when the very lowest individual bins are quiet.
                let bassEnergy = 0
                const count = Math.min(6, root.spectrumData.length)
                for (let index = 0; index < count; ++index) {
                    const level = root.spectrumData[index] / 16
                    bassEnergy += level * level
                }
                root.consumeBass(count ? Math.sqrt(bassEnergy / count) : 0)
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
        running: root.visualizerActive
        onTriggered: if (!spectrumProcess.running) spectrumProcess.running = true
    }

    Timer {
        interval: 40
        repeat: true
        running: !SettingsState.calmMode && !SettingsState.reducedMotion
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

                    WorkspaceGroup { screenName: modelData.name }
                    Item { Layout.fillWidth: true }
                    SystemGroup { connectivityAnchorItem: connectivityPopupAnchor }
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
                        active: root.visualizerActive
                        mirrored: true
                        spectrumData: root.spectrumData
                        burstLevel: root.beatBurst
                    }

                    ClockWeather {
                        id: clockWeather
                        onClicked: {
                            const opening = !calendarWeather.requestedOpen
                            SettingsState.mediaScreen = ""
                            SettingsState.connectivityOpen = false
                            if (opening) SettingsState.overlayOpened("calendar")
                            calendarWeather.requestedOpen = opening
                        }
                    }

                    MediaPill {
                        id: mediaPill
                        player: root.activeMediaPlayer
                        onClicked: {
                            calendarWeather.requestedOpen = false
                            SettingsState.mediaScreen = SettingsState.mediaScreen === modelData.name ? "" : modelData.name
                        }
                    }

                    MediaVisualizerWing {
                        active: root.visualizerActive
                        spectrumData: root.spectrumData
                        burstLevel: root.beatBurst
                    }
                }

                MediaPanel {
                    screen: modelData
                    anchorItem: mediaPill
                    player: root.activeMediaPlayer
                    players: root.mediaPlayers
                    spectrumData: root.spectrumData
                    requestedOpen: SettingsState.mediaScreen === modelData.name
                    onCloseRequested: SettingsState.mediaScreen = ""
                    onPlayerSelected: selectedPlayer => { root.preferredPlayer = selectedPlayer; root.refreshActivePlayer() }
                }

                Connections {
                    target: SettingsState
                    function onOverlayOpened(name) { if (name !== "calendar") calendarWeather.requestedOpen = false }
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

            // This uses PanelWindow coordinates, so its right edge is exactly
            // the same inset as Control Center and Notifications.
            Item {
                id: connectivityPopupAnchor
                width: 1
                height: 1
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: Theme.panelPopupRightInset
                anchors.topMargin: Theme.panelPopupCardTop - Theme.panelPopupGap - height
            }
        }
    }
}
