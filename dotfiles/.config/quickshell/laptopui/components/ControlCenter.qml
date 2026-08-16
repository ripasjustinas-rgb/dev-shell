import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Item {
    id: root
    property bool open: false
    signal closeRequested()
    property string sinkVolume: "—"
    property string sourceVolume: "—"
    property string brightness: "—"
    property string profile: Capabilities.activePowerProfile || "unavailable"
    property real clipboardHeight: 0
    property real sinkLevel: 0
    property real sourceLevel: 0
    property real brightnessLevel: 0
    property bool sinkMuted: false
    property bool sourceMuted: false
    property string pendingVolumeTarget: ""
    property real pendingVolumeLevel: 0
    property real pendingBrightnessLevel: 0

    function refresh() {
        if (Capabilities.hasAudioSink) sinkQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
        if (Capabilities.hasAudioSource) sourceQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"])
        if (Capabilities.hasBacklight && Capabilities.hasBrightnessctl) brightnessQuery.exec(["brightnessctl", "-m"])
    }
    function parseVolume(text, microphone) {
        const match = text.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/)
        const level = match ? Math.round(Number(match[1]) * 100) : 0
        const value = match ? level + "%" : "—"
        const muted = match ? Boolean(match[2]) : false
        if (microphone) {
            sourceVolume = value
            sourceLevel = level
            sourceMuted = muted
        } else {
            sinkVolume = value
            sinkLevel = level
            sinkMuted = muted
        }
    }
    function queueVolume(target, level) {
        pendingVolumeTarget = target
        pendingVolumeLevel = level
        volumeApply.restart()
    }
    function queueBrightness(level) {
        pendingBrightnessLevel = level
        brightnessApply.restart()
    }
    function mute(target) { Quickshell.execDetached(["wpctl", "set-mute", target, "toggle"]); delayedRefresh.restart() }
    function setBrightness(level) { Quickshell.execDetached(["brightnessctl", "set", Math.round(level) + "%"]); delayedRefresh.restart() }

    Process { id: sinkQuery; stdout: StdioCollector { onStreamFinished: root.parseVolume(text, false) } }
    Process { id: sourceQuery; stdout: StdioCollector { onStreamFinished: root.parseVolume(text, true) } }
    Process { id: brightnessQuery; stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(","); root.brightness = p.length > 3 ? p[3].trim() : "—"; root.brightnessLevel = p.length > 3 ? Number.parseFloat(p[3]) : 0 } } }
    Timer { id: volumeApply; interval: 70; onTriggered: { Quickshell.execDetached(["wpctl", "set-volume", root.pendingVolumeTarget, Math.round(root.pendingVolumeLevel) + "%"]); delayedRefresh.restart() } }
    Timer { id: brightnessApply; interval: 70; onTriggered: root.setBrightness(root.pendingBrightnessLevel) }
    Timer { id: delayedRefresh; interval: 180; onTriggered: root.refresh() }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            focusable: true
            Keys.onEscapePressed: root.closeRequested()

            MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }

            Rectangle {
                id: card
                width: 390
                height: Math.min(
                    parent.height - Theme.panelHeight - 28,
                    Math.max(390, 365 + root.clipboardHeight)
                )
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Theme.panelHeight + 14
                anchors.rightMargin: 14
                radius: 20
                color: Theme.background
                border.color: Theme.border
                border.width: 1
                opacity: root.open ? 1 : 0
                y: root.open ? Theme.panelHeight + 14 : Theme.panelHeight - 12
                Behavior on opacity { NumberAnimation { duration: 180 } }
                scale: root.open ? 1 : 0.97
                Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

                MouseArea { anchors.fill: parent }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Control center"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 17; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: "󰅖"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 16
                            MouseArea { anchors.fill: parent; onClicked: root.closeRequested() } }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }
                    ControlRow { visible: Capabilities.hasAudioSink; icon: root.sinkMuted ? "󰖁" : "󰕾"; title: "Volume"; value: root.sinkVolume; level: root.sinkLevel; muted: root.sinkMuted; muteAvailable: true; muteIcon: root.sinkMuted ? "󰖁" : "󰕾"; deviceSelectionAvailable: true; onLevelRequested: level => root.queueVolume("@DEFAULT_AUDIO_SINK@", level); onMuteRequested: root.mute("@DEFAULT_AUDIO_SINK@"); onDeviceSelectionChanged: delayedRefresh.restart() }
                    ControlRow { visible: Capabilities.hasAudioSource; icon: root.sourceMuted ? "󰍭" : "󰍬"; title: "Microphone"; value: root.sourceVolume; level: root.sourceLevel; muted: root.sourceMuted; muteAvailable: true; muteIcon: root.sourceMuted ? "󰍭" : "󰍬"; deviceSelectionAvailable: true; microphone: true; onLevelRequested: level => root.queueVolume("@DEFAULT_AUDIO_SOURCE@", level); onMuteRequested: root.mute("@DEFAULT_AUDIO_SOURCE@"); onDeviceSelectionChanged: delayedRefresh.restart() }
                    ControlRow { visible: Capabilities.hasBacklight && Capabilities.hasBrightnessctl; icon: "󰃠"; title: "Brightness"; value: root.brightness; level: root.brightnessLevel; onLevelRequested: level => root.queueBrightness(level) }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8
                        QuickToggle { Layout.fillWidth: true; Layout.preferredWidth: 0; visible: Capabilities.hasWifi; icon: "󰤨"; label: Networking.wifiEnabled ? "Wi-Fi" : "Wi-Fi off"; active: Networking.wifiEnabled; onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
                        QuickToggle { Layout.fillWidth: true; Layout.preferredWidth: 0; visible: Capabilities.powerProfilesAvailable; icon: "󰂄"; label: root.profile; active: root.profile === "performance"; onClicked: profilePopup.open = !profilePopup.open }
                        QuickToggle { Layout.fillWidth: true; Layout.preferredWidth: 0; icon: "󰏤"; label: SettingsState.calmMode ? "Calm" : "Effects"; active: SettingsState.calmMode; onClicked: SettingsState.toggleCalmMode() }
                        QuickToggle { Layout.fillWidth: true; Layout.preferredWidth: 0; icon: "󰂚"; label: SettingsState.dnd ? "DND" : "Notifications"; active: SettingsState.dnd; onClicked: SettingsState.toggleDnd() }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }
                    ClipboardHistory {
                        id: clipboardHistory
                        onImplicitHeightChanged: root.clipboardHeight = implicitHeight
                    }
                }

                Rectangle {
                    id: profilePopup
                    property bool open: false
                    visible: open
                    width: 190; height: 116; radius: 12
                    color: Theme.elevated; border.color: Theme.border; border.width: 1
                    anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 18
                    Column {
                        anchors.fill: parent; anchors.margins: 8; spacing: 2
                        Repeater { model: Capabilities.powerProfiles
                            delegate: QuickMenuItem { required property string modelData; text: modelData; active: root.profile === modelData; onClicked: { Capabilities.setPowerProfile(modelData); profilePopup.open = false; delayedRefresh.restart() } }
                        }
                    }
                }
            }
            onVisibleChanged: if (visible) {
                root.refresh()
                clipboardHistory.refresh()
            }
        }
    }
}
