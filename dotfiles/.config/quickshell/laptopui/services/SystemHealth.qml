import QtQuick
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property real cpuUsage: 0
    property real previousIdle: 0
    property real previousTotal: 0
    property real ramUsed: 0
    property real ramTotal: 0
    readonly property int ramPercent: ramTotal > 0 ? Math.round(ramUsed / ramTotal * 100) : 0

    FileView {
        id: cpuFile

        path: "/proc/stat"
        watchChanges: false
        onLoaded: {
            // Guest time is already included in user/nice; don't count it twice.
            const values = text().split("\n")[0].trim().split(/\s+/).slice(1, 9).map(Number);
            const idle = values[3] + values[4];
            const total = values.reduce((sum, value) => {
                return sum + value;
            }, 0);
            const delta = total - root.previousTotal;
            if (root.previousTotal > 0 && delta > 0)
                root.cpuUsage = Math.max(0, Math.min(100, 100 * (1 - (idle - root.previousIdle) / delta)));

            root.previousIdle = idle;
            root.previousTotal = total;
        }
    }

    FileView {
        id: memoryFile

        path: "/proc/meminfo"
        watchChanges: false
        onLoaded: {
            const lines = text().split("\n");
            root.ramTotal = valueFor(lines, "MemTotal:");
            root.ramUsed = root.ramTotal - valueFor(lines, "MemAvailable:");
        }

        function valueFor(lines, key) {
            const line = lines.find((value) => {
                return value.startsWith(key);
            });
            return line ? parseInt(line.split(/\s+/)[1]) : 0;
        }

    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuFile.reload();
            memoryFile.reload();
        }
    }

}
