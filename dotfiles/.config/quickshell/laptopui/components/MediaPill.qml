import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root
    property var player: null
    property string displayedArtSource: ""

    readonly property bool hasPlayer: player !== null
    readonly property bool playing: hasPlayer && player.playbackState === MprisPlaybackState.Playing
    readonly property string titleText: hasPlayer && player.trackTitle
        ? player.trackTitle : (hasPlayer && player.identity ? player.identity : "Media")
    readonly property string artistText: hasPlayer && player.trackArtist
        ? player.trackArtist : (hasPlayer && player.trackAlbum ? player.trackAlbum : "")

    function normalizedArtSource(path) {
        if (!path) return ""
        const source = String(path)
        if (source.startsWith("/") && !source.startsWith("//")) return "file://" + source
        return source
    }

    function refreshArt() {
        displayedArtSource = player ? normalizedArtSource(player.trackArtUrl) : ""
    }

    visible: hasPlayer
    implicitWidth: visible ? 252 : 0
    implicitHeight: Theme.panelContentHeight - 6
    onPlayerChanged: refreshArt()

    Connections {
        target: root.player
        function onTrackArtUrlChanged() { root.refreshArt() }
        function onTrackChanged() { root.refreshArt() }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.surfaceHover
        border.width: 1
        border.color: Theme.glassBorder

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Theme.radius - 1
            color: "transparent"
            border.width: 1
            border.color: Theme.glassHighlight
            opacity: 0.38
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 6

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 8
            color: Theme.surface
            clip: true

            Image {
                anchors.fill: parent
                visible: root.displayedArtSource.length > 0
                source: visible ? root.displayedArtSource : ""
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                cache: false
            }

            Text {
                anchors.centerIn: parent
                visible: root.displayedArtSource.length === 0
                text: root.playing ? "󰎈" : "󰏤"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: -2

            Text {
                Layout.fillWidth: true
                text: root.titleText
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.artistText.length > 0
                text: root.artistText
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 8
            visible: root.hasPlayer && root.player.canTogglePlaying
            color: playMouse.containsMouse ? Theme.accent : "transparent"
            border.width: 1
            border.color: playMouse.containsMouse ? Theme.accent : Theme.border

            Text {
                anchors.centerIn: parent
                text: root.playing ? "󰏤" : "󰐊"
                color: playMouse.containsMouse ? Theme.accentText : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
            MouseArea {
                id: playMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.player.togglePlaying()
            }
        }

        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 8
            visible: root.hasPlayer && root.player.canGoNext
            color: nextMouse.containsMouse ? Theme.elevated : "transparent"
            border.width: 1
            border.color: Theme.border

            Text {
                anchors.centerIn: parent
                text: "󰒭"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.player.next()
            }
        }
    }
}
