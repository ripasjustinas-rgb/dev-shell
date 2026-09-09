import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.services
import qs.theme

PanelWindow {
    id: root

    property Item anchorItem
    property var player: null
    property var players: []
    property var spectrumData: []
    property bool requestedOpen: false
    property real position: 0
    readonly property bool playing: player && player.playbackState === MprisPlaybackState.Playing
    readonly property bool hasTimeline: player !== null && player.lengthSupported && player.positionSupported && player.length > 0

    signal playerSelected(var selectedPlayer)
    signal closeRequested()

    function commitSeek(value) {
        if (!player || !player.canSeek)
            return ;

        if (hasTimeline) {
            player.position = value;
            position = value;
        } else {
            player.seek(value);
        }
        seekBar.value = Qt.binding(() => {
            return root.hasTimeline ? root.position : 0;
        });
    }

    function timestamp(seconds) {
        const value = Math.max(0, Math.floor(seconds || 0));
        return Math.floor(value / 60) + ":" + String(value % 60).padStart(2, "0");
    }

    exclusionMode: ExclusionMode.Ignore
    focusable: true
    color: "transparent"
    visible: requestedOpen && player !== null
    onVisibleChanged: {
        if (visible) {
            position = player.position;
            card.forceActiveFocus();
        }
    }
    onPlayerChanged: position = player ? player.position : 0

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Timer {
        interval: 500
        running: root.visible && root.playing && root.player.positionSupported
        repeat: true
        onTriggered: root.position = root.player.position
    }

    Connections {
        function onPositionChanged() {
            root.position = root.player.position;
        }

        function onTrackChanged() {
            root.position = root.player.position;
        }

        target: root.player
    }

    Shortcut {
        enabled: root.visible
        sequence: "Escape"
        onActivated: root.closeRequested()
    }

    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Theme.panelPopupCardTop
        width: Math.min(420, parent.width - 28)
        height: Math.min(contents.implicitHeight + 36, parent.height - Theme.panelPopupCardTop - 20)
        clip: true
        radius: Theme.radiusLarge
        color: Theme.popupBackground
        border.color: Theme.glassBorder
        border.width: 1
        Keys.onEscapePressed: root.closeRequested()

        MouseArea {
            anchors.fill: parent
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 18
            contentHeight: contents.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: contents

                width: parent.width
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: root.player ? root.player.identity : "Now playing"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    ActionButton {
                        text: "Close"
                        onClicked: root.closeRequested()
                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 132
                        Layout.preferredHeight: 132
                        radius: Theme.radius
                        color: Theme.surface
                        clip: true

                        Image {
                            id: art

                            anchors.fill: parent
                            source: root.player ? root.player.trackArtUrl : ""
                            sourceSize.width: 264
                            sourceSize.height: 264
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: art.status !== Image.Ready
                            text: "󰎈"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 46
                        }

                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: root.player ? root.player.trackTitle || "Unknown track" : ""
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.bold: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.player ? root.player.trackArtist : ""
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.player ? root.player.trackAlbum : ""
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }

                    }

                }

                Row {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    visible: Capabilities.hasCava && !SettingsState.calmMode && !SettingsState.reducedMotion
                    spacing: 4

                    Repeater {
                        model: 32

                        Rectangle {
                            required property int index

                            width: Math.max(1, (parent.width - 31 * 4) / 32)
                            height: root.playing ? Math.max(2, Number(root.spectrumData[index] || 0) * 4) : 2
                            y: 64 - height
                            radius: width / 2
                            color: index < 16 ? Theme.accent : Theme.secondary
                            opacity: 0.55 + height / 144

                            Behavior on height {
                                NumberAnimation {
                                    duration: SettingsState.reducedMotion ? 0 : (65)
                                }

                            }

                        }

                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Slider {
                        id: seekBar

                        Layout.fillWidth: true
                        from: root.hasTimeline ? 0 : -60
                        to: root.hasTimeline ? root.player.length : 60
                        value: root.hasTimeline ? root.position : 0
                        stepSize: root.hasTimeline ? 0 : 1
                        enabled: root.player && root.player.canSeek
                        Accessible.name: root.hasTimeline ? "Track position" : "Seek backward or forward up to 60 seconds"
                        onPressedChanged: {
                            if (!pressed) {
                                root.commitSeek(value);
                            }
                        }
                        onMoved: {
                            if (!pressed) {
                                root.commitSeek(value);
                            }
                        }

                        background: Rectangle {
                            x: seekBar.leftPadding
                            y: seekBar.topPadding + seekBar.availableHeight / 2 - height / 2
                            width: seekBar.availableWidth
                            height: 6
                            radius: height / 2
                            color: Theme.elevated

                            Rectangle {
                                width: seekBar.visualPosition * parent.width
                                height: parent.height
                                radius: parent.radius
                                color: seekBar.enabled ? Theme.accent : Theme.muted
                                opacity: root.hasTimeline ? 1 : 0.45
                            }

                        }

                        handle: Rectangle {
                            x: seekBar.leftPadding + seekBar.visualPosition * (seekBar.availableWidth - width)
                            y: seekBar.topPadding + seekBar.availableHeight / 2 - height / 2
                            width: 14
                            height: 14
                            radius: 7
                            color: seekBar.enabled ? Theme.accent : Theme.muted
                            border.width: seekBar.activeFocus ? 2 : 0
                            border.color: Theme.text
                        }

                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.hasTimeline ? root.timestamp(seekBar.pressed ? seekBar.value : root.position) : "−60s"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: !root.hasTimeline
                            text: seekBar.pressed ? (seekBar.value > 0 ? "+" : "") + Math.round(seekBar.value) + "s" : "Drag to seek"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        Item {
                            Layout.fillWidth: true
                            visible: !root.hasTimeline
                        }

                        Text {
                            text: root.hasTimeline ? root.timestamp(root.player.length) : "+60s"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                    }

                    Text {
                        Layout.fillWidth: true
                        visible: !root.hasTimeline || !seekBar.enabled
                        text: !seekBar.enabled ? "This player does not support seeking." : "This player does not report track duration. Seek by a relative offset."
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        wrapMode: Text.Wrap
                    }

                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter

                    ActionButton {
                        text: "Previous"
                        enabled: root.player && root.player.canGoPrevious
                        onClicked: root.player.previous()
                    }

                    ActionButton {
                        text: root.playing ? "Pause" : "Play"
                        highlighted: true
                        enabled: root.player && root.player.canTogglePlaying
                        onClicked: root.player.togglePlaying()
                    }

                    ActionButton {
                        text: "Next"
                        enabled: root.player && root.player.canGoNext
                        onClicked: root.player.next()
                    }

                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter

                    ActionButton {
                        text: "Shuffle"
                        visible: root.player && root.player.shuffleSupported
                        highlighted: root.player ? root.player.shuffle : false
                        enabled: root.player && root.player.canControl
                        onClicked: root.player.shuffle = !root.player.shuffle
                    }

                    ActionButton {
                        text: root.player && root.player.loopState === MprisLoopState.Track ? "Repeat track" : root.player && root.player.loopState === MprisLoopState.Playlist ? "Repeat all" : "Repeat off"
                        visible: root.player && root.player.loopSupported
                        highlighted: root.player && root.player.loopState !== MprisLoopState.None
                        enabled: root.player && root.player.canControl
                        onClicked: root.player.loopState = (root.player.loopState + 1) % 3
                    }

                }

                Flow {
                    Layout.fillWidth: true
                    visible: root.players.length > 1
                    spacing: 6

                    Repeater {
                        model: root.players

                        ActionButton {
                            required property var modelData

                            text: modelData.identity
                            highlighted: modelData === root.player
                            onClicked: root.playerSelected(modelData)
                        }

                    }

                }

            }

        }

    }

}
