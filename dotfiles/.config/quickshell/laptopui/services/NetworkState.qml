import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property bool active: SettingsState.connectivityOpen || SettingsState.controlOpen
    property var info: ({
    })
    property var previous: ({
    })
    property double previousTime: 0
    property real download: 0
    property real upload: 0
    property real received: 0
    property real transmitted: 0
    property var downloadHistory: []
    property var uploadHistory: []
    property string result: ""
    property string testResult: ""
    property string diagnosticInterface: ""
    property string speedtestInterface: ""
    readonly property bool diagnosing: diagnostic.running
    readonly property bool testing: speedTest.running
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/laptopui-network-info"

    function rate(value) {
        return value >= 125000 ? (value * 8 / 1e+06).toFixed(1) + " Mb/s" : (value * 8 / 1000).toFixed(0) + " kb/s";
    }

    function bytes(value) {
        return value >= 1.07374e+09 ? (value / 1.07374e+09).toFixed(2) + " GiB" : (value / 1.04858e+06).toFixed(1) + " MiB";
    }

    function refresh() {
        if (!metadata.running)
            metadata.exec([helper, "snapshot"]);

    }

    function diagnose() {
        if (!diagnostic.running) {
            diagnosticInterface = info.interface || "";
            result = "";
            diagnostic.exec([helper, "diagnose"]);
        }
    }

    function speedtest() {
        if (!speedTest.running && info.speedtestAvailable) {
            speedtestInterface = info.interface || "";
            testResult = "";
            speedTest.exec([helper, "speedtest"]);
        }
    }

    function decode(text) {
        try {
            return JSON.parse(text);
        } catch (_) {
            return {
                "error": "Network information unavailable"
            };
        }
    }

    onActiveChanged: {
        previous = ({
        });
        previousTime = 0;
        download = 0;
        upload = 0;
        downloadHistory = [];
        uploadHistory = [];
        if (active)
            refresh();

    }

    Process {
        id: metadata

        stdout: StdioCollector {
            onStreamFinished: {
                const next = root.decode(text);
                if (next.interface !== root.info.interface) {
                    root.previous = ({
                    });
                    root.previousTime = 0;
                    root.downloadHistory = [];
                    root.uploadHistory = [];
                    root.result = "";
                    root.testResult = "";
                }
                root.info = next;
            }
        }

    }

    Process {
        id: diagnostic

        stdout: StdioCollector {
            onStreamFinished: {
                const data = root.decode(text);
                root.result = root.diagnosticInterface === root.info.interface ? data.result || data.error || "Probe failed" : "Connection changed; run the check again.";
            }
        }

    }

    Process {
        id: speedTest

        stdout: StdioCollector {
            onStreamFinished: {
                const data = root.decode(text);
                root.testResult = root.speedtestInterface === root.info.interface ? data.result || data.error || "Test failed" : "Connection changed during speed test; run it again.";
            }
        }

    }

    FileView {
        id: counters

        path: "/proc/net/dev"
        watchChanges: false
        onLoaded: {
            const now = Date.now();
            const elapsed = (now - root.previousTime) / 1000;
            let found = false;
            for (const line of text().split("\n")) {
                const split = line.indexOf(":");
                if (split < 0 || line.slice(0, split).trim() !== root.info.interface)
                    continue;

                const values = line.slice(split + 1).trim().split(/\s+/).map(Number);
                const rx = values[0], tx = values[8];
                root.received = rx;
                root.transmitted = tx;
                if (root.previousTime > 0 && elapsed > 0 && root.previous.rx !== undefined && rx >= root.previous.rx && tx >= root.previous.tx) {
                    root.download = (rx - root.previous.rx) / elapsed;
                    root.upload = (tx - root.previous.tx) / elapsed;
                    root.downloadHistory = root.downloadHistory.concat([root.download]).slice(-60);
                    root.uploadHistory = root.uploadHistory.concat([root.upload]).slice(-60);
                } else {
                    root.download = 0;
                    root.upload = 0;
                }
                root.previous = {
                    "rx": rx,
                    "tx": tx
                };
                found = true;
                break;
            }
            if (!found) {
                root.download = 0;
                root.upload = 0;
                root.received = 0;
                root.transmitted = 0;
                root.previous = ({
                });
            }
            root.previousTime = now;
        }
    }

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: counters.reload()
    }

    Timer {
        interval: 5000
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

}
