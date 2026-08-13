import Quickshell.Io
import QtQuick
import qs.theme

PanelButton {
    id: root
    property string profile: "unavailable"
    property bool performanceAvailable: false
    label: profile === "performance" ? "󰓅" : profile === "power-saver" ? "󰾆" : "󰾅"
    labelColor: profile === "performance" ? Theme.danger
        : profile === "power-saver" ? Theme.success
        : profile === "balanced" ? Theme.accent : Theme.muted
    tooltip: "Power profile: " + profile

    function refresh() {
        profileQuery.exec(["powerprofilesctl", "get"])
        profilesQuery.exec(["powerprofilesctl", "list"])
    }

    onClicked: {
        const next = performanceAvailable
            ? (profile === "performance" ? "balanced" : "performance")
            : (profile === "power-saver" ? "balanced" : "power-saver")
        setProfile.exec(["powerprofilesctl", "set", next])
    }

    Process {
        id: profileQuery
        stdout: StdioCollector { onStreamFinished: root.profile = text.trim().length ? text.trim() : "unavailable" }
    }
    Process {
        id: profilesQuery
        stdout: StdioCollector { onStreamFinished: root.performanceAvailable = text.indexOf("performance:") >= 0 }
    }
    Process { id: setProfile; onExited: refreshDelay.restart() }
    Timer { id: refreshDelay; interval: 180; onTriggered: root.refresh() }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
