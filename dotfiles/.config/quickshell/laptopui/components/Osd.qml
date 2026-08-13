import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root
    property string kind: "volume"
    property string value: ""
    property string icon: "󰕾"
    property bool shown: false

    function show(requestedKind) {
        kind = requestedKind
        if (kind === "brightness") {
            icon = "󰃠"
            valueQuery.exec(["brightnessctl", "-m"])
        } else if (kind === "mic") {
            icon = "󰍬"
            valueQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"])
        } else {
            icon = "󰕾"
            valueQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
        }
        shown = true
        hideTimer.restart()
    }

    Process {
        id: valueQuery
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.kind === "brightness") {
                    const parts = text.trim().split(",")
                    root.value = parts.length > 3 ? parts[3].trim() : "—"
                } else {
                    const match = text.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/)
                    root.value = match ? Math.round(Number(match[1]) * 100) + "%" : "—"
                    if (match && match[2]) root.icon = root.kind === "mic" ? "󰍭" : "󰖁"
                }
            }
        }
    }

    Timer { id: hideTimer; interval: 1400; onTriggered: root.shown = false }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.shown
            implicitWidth: 220
            implicitHeight: 70
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            anchors { bottom: true; left: true; right: true }

            Rectangle {
                anchors.centerIn: parent
                width: 220
                height: 58
                radius: 16
                color: Theme.background
                border.color: Theme.border
                border.width: 1
                opacity: root.shown ? 1 : 0
                scale: root.shown ? 1 : 0.92
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12
                    Text { text: root.icon; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 22 }
                    Text { text: root.kind === "brightness" ? "Brightness" : (root.kind === "mic" ? "Microphone" : "Volume"); color: Theme.text; font.family: Theme.fontFamily; Layout.fillWidth: true }
                    Text { text: root.value; color: Theme.accent; font.family: Theme.fontFamily; font.bold: true }
                }
            }
        }
    }
}
