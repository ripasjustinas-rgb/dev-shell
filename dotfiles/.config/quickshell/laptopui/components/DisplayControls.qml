import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme

ColumnLayout {
    id: root

    property bool expanded: false
    property bool active: false
    property var monitors: []
    property string error: ""
    property int temperature: 6500
    property bool nightLightAvailable: false

    function refresh() {
        if (!monitorQuery.running)
            monitorQuery.exec(["hyprctl", "monitors", "-j"]);

        if (!nightQuery.running)
            nightQuery.exec(["sh", "-c", "command -v hyprsunset >/dev/null 2>&1 && hyprctl hyprsunset temperature 2>/dev/null || true"]);

    }

    spacing: 8
    onExpandedChanged: {
        if (expanded && active) {
            refresh();
        }
    }
    onActiveChanged: {
        if (!active) {
            expanded = false;
        }
    }

    Process {
        id: monitorQuery

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text);
                } catch (_) {
                    root.monitors = [];
                }
            }
        }

    }

    Process {
        id: nightQuery

        stdout: StdioCollector {
            onStreamFinished: {
                const value = Number(text.trim());
                root.nightLightAvailable = text.trim().length > 0 && Number.isFinite(value) && value >= 1000 && value <= 20000;
                if (root.nightLightAvailable)
                    root.temperature = value;

            }
        }

    }

    Process {
        id: nightApply

        onExited: (code, status) => {
            if (code !== 0)
                root.error = "Night light could not be changed";

            root.refresh();
        }

        stdout: StdioCollector {
            onStreamFinished: root.error = text.trim() === "ok" || !text.trim().length ? "" : text.trim()
        }

    }

    Timer {
        interval: 5000
        running: root.active && root.expanded
        repeat: true
        onTriggered: root.refresh()
    }

    SectionHeader {
        Layout.fillWidth: true
        title: "Displays"
        summary: Quickshell.screens.length + " connected"
        expanded: root.expanded
        onClicked: root.expanded = !root.expanded
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.expanded
        spacing: 8

        Repeater {
            model: root.monitors

            ColumnLayout {
                required property var modelData

                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: modelData.name + (modelData.focused ? " · active" : "")
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: modelData.width + " × " + modelData.height + " · " + Number(modelData.refreshRate).toFixed(0) + " Hz · " + Math.round(modelData.scale * 100) + "% scale"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    wrapMode: Text.Wrap
                }

            }

        }

        Text {
            visible: root.monitors.length === 0
            text: "Display details unavailable"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }

        RowLayout {
            visible: root.nightLightAvailable

            ActionButton {
                text: "Normal"
                highlighted: root.temperature >= 6500
                onClicked: nightApply.exec(["hyprctl", "hyprsunset", "identity"])
            }

            ActionButton {
                text: "Warm"
                highlighted: root.temperature >= 4000 && root.temperature < 6500
                onClicked: nightApply.exec(["hyprctl", "hyprsunset", "temperature", "4500"])
            }

            ActionButton {
                text: "Warmer"
                highlighted: root.temperature < 4000
                onClicked: nightApply.exec(["hyprctl", "hyprsunset", "temperature", "3200"])
            }

        }

        Text {
            Layout.fillWidth: true
            visible: !root.nightLightAvailable
            text: "Night light is available when hyprsunset is running."
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 10
            wrapMode: Text.Wrap
        }

        ActionButton {
            text: SettingsState.reducedMotion ? "Reduced motion: on" : "Reduced motion: off"
            highlighted: SettingsState.reducedMotion
            onClicked: {
                SettingsState.reducedMotion = !SettingsState.reducedMotion;
                SettingsState.save();
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.error.length > 0
            text: root.error
            color: Theme.danger
            font.family: Theme.fontFamily
            font.pixelSize: 10
            wrapMode: Text.Wrap
        }

    }

}
