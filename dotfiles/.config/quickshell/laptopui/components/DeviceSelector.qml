import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.theme

PopupWindow {
    id: root
    property Item anchorItem
    property bool microphone: false
    property var devices: []
    property string statusText: ""
    property var connectedOutputs: []
    signal deviceSelected()

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
    implicitWidth: 290
    implicitHeight: content.implicitHeight
    visible: false
    color: "transparent"
    grabFocus: true

    function refresh() {
        statusQuery.exec(["wpctl", "status"])
        monitorQuery.exec(["hyprctl", "monitors", "-j"])
    }

    function parseDevices(text) {
        statusText = text
        rebuildDevices()
    }

    function parseMonitors(text) {
        try {
            connectedOutputs = JSON.parse(text).map(monitor => monitor.name)
        } catch (_) {
            connectedOutputs = []
        }
        rebuildDevices()
    }

    function externalOutputIsConnected(name) {
        if (!name.includes("HDMI / DisplayPort")) return true
        const port = name.match(/(?:HDMI|DisplayPort)\s+(\d+)\s+Output/)
        if (!port) return false
        const suffix = new RegExp("(?:DP|HDMI-A?)-" + port[1] + "$", "i")
        return connectedOutputs.some(output => suffix.test(output))
    }

    function rebuildDevices() {
        if (!statusText.length) return
        const wantedSection = microphone ? "Sources:" : "Sinks:"
        let inAudioSection = false
        let inWantedSection = false
        const parsed = []
        for (const line of statusText.split("\n")) {
            const heading = line.trim()
            if (heading === "Audio") {
                inAudioSection = true
                inWantedSection = false
                continue
            }
            if (heading === "Video" || heading === "Settings") {
                inAudioSection = false
                inWantedSection = false
                continue
            }
            if (!inAudioSection) continue
            const section = line.match(/\b(Devices|Sinks|Sources|Filters|Streams):/)
            if (section) {
                inWantedSection = section[1] + ":" === wantedSection
                continue
            }
            if (!inWantedSection) continue
            const match = line.match(/(\*)?\s*(\d+)\.\s+(.+?)(?:\s+\[vol:.*)?$/)
            if (!match) continue
            const name = match[3].trim().replace(/^.*? HD Audio /, "")
            if (!microphone && !externalOutputIsConnected(name)) continue
            parsed.push({
                id: match[2],
                name: name,
                active: Boolean(match[1])
            })
        }
        devices = parsed
    }

    Process {
        id: statusQuery
        stdout: StdioCollector { onStreamFinished: root.parseDevices(text) }
    }
    Process {
        id: monitorQuery
        stdout: StdioCollector { onStreamFinished: root.parseMonitors(text) }
    }
    Timer {
        id: selectionRefresh
        interval: 180
        onTriggered: {
            root.refresh()
            root.deviceSelected()
        }
    }

    onVisibleChanged: if (visible) refresh()

    Rectangle {
        id: content
        anchors.fill: parent
        anchors.topMargin: 6
        radius: Theme.radius
        color: Theme.background
        border.color: Theme.border
        border.width: 1
        implicitHeight: Math.min(280, Math.max(76, 48 + deviceList.contentHeight + 12))

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            Text {
                text: root.microphone ? "Input device" : "Output device"
                color: Theme.text
                font.family: Theme.fontFamily
                font.bold: true
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }
            ListView {
                id: deviceList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(200, contentHeight)
                Layout.maximumHeight: 200
                clip: true
                spacing: 4
                model: root.devices
                delegate: Rectangle {
                    required property var modelData
                    width: deviceList.width
                    height: 38
                    radius: 9
                    color: deviceMouse.containsMouse || modelData.active ? Theme.surfaceHover : Theme.surface
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        Text { text: modelData.active ? "✓" : ""; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.preferredWidth: 14 }
                        Text { text: modelData.name; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    MouseArea {
                        id: deviceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            Quickshell.execDetached(["wpctl", "set-default", modelData.id])
                            selectionRefresh.restart()
                        }
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                visible: root.devices.length === 0
                text: "No devices available"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }
}
