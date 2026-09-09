import QtQuick
import Quickshell
import qs.components

ShellRoot {
    QtObject {
        id: player

        property real position: 0
        property real length: 180
        property bool lengthSupported: true
        property bool positionSupported: true
        property bool canSeek: true
        property int playbackState: 2
        property string identity: "Test player"
        property string trackTitle: "Seek regression"
        property string trackArtist: ""
        property string trackAlbum: ""
        property string trackArtUrl: ""
        property bool canGoPrevious: false
        property bool canGoNext: false
        property bool canTogglePlaying: false
        property bool shuffleSupported: false
        property bool shuffle: false
        property bool loopSupported: false
        property int loopState: 0
        property bool canControl: true
        property real lastOffset: 0

        signal trackChanged()

        function seek(offset) {
            lastOffset = offset;
        }

    }

    MediaPanel {
        id: panel

        player: player
    }

    ClipboardHistory {
        id: clipboard

        visible: false
    }

    MediaVisualizerWing {
        id: compactVisualizer

        visible: false
    }

    Timer {
        interval: 250
        running: true
        onTriggered: {
            check(panel.hasTimeline, "Duration should enable the timeline");
            panel.commitSeek(42);
            check(player.position === 42, "Absolute seeking must set track position");
            player.lengthSupported = false;
            check(!panel.hasTimeline, "Missing duration must use relative seeking");
            panel.commitSeek(-10);
            check(player.lastOffset === -10, "Relative seeking must preserve negative offsets");
            player.canSeek = false;
            panel.commitSeek(20);
            check(player.lastOffset === -10, "Unsupported seek must not call the player");
            panel.player = null;
            panel.commitSeek(5);
            check(!panel.hasTimeline, "A disappearing player must clear the timeline");
            clipboard.parseEntries("5\tfive\n4\tfour\n3\tthree\n2\ttwo\n1\tone");
            check(clipboard.displayedEntries.length === 3, "Collapsed clipboard must show exactly three recent entries");
            check(clipboard.displayedEntries[0].id === "5", "Clipboard order must remain newest first");
            clipboard.expanded = true;
            check(clipboard.displayedEntries.length === 5, "Expanded clipboard must show older entries");
            clipboard.parseEntries("");
            check(clipboard.displayedEntries.length === 0 && clipboard.totalCount === 0, "Empty history must clear visible entries");
            const highOnly = Array(32).fill(0);
            highOnly[31] = 16;
            compactVisualizer.spectrumData = highOnly;
            check(compactVisualizer.laneLevel(0) > 0.4, "Compact visualizer must include the highest Cava bins");
            const previouslySkipped = Array(32).fill(0);
            previouslySkipped[15] = 16;
            compactVisualizer.spectrumData = previouslySkipped;
            check(compactVisualizer.laneLevel(1) > 0.2, "Compact visualizer must not leave gaps between sampled frequencies");
            console.log("MEDIA_SMOKE_PASSED");
            Qt.quit();
        }

        function check(condition, message) {
            if (!condition)
                throw new Error(message);

        }

    }

}
