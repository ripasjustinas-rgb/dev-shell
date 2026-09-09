import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Item {
    id: root
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (root.open && !Quickshell.screens.some(screen => screen.name === root.targetScreen)) root.closeRequested()
        }
    }
    property string targetScreen: ""
    property bool open: false
    property bool closing: false
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
    property bool advancedAudio: false
    property bool clipboardExpanded: false
    property string pendingVolumeTarget: ""
    property real pendingVolumeLevel: 0
    property real pendingBrightnessLevel: 0

    onOpenChanged: {
        if (open) targetScreen = SettingsState.focusedScreen
        if (!open) {
            closing = true
            advancedAudio = false
            clipboardExpanded = false
            streamModel.clear()
        }
    }

    function refresh() {
        if (Capabilities.hasAudioSink) {
            sinkQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]);
        }
        if (Capabilities.hasAudioSource) {
            sourceQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]);
        }
        if (Capabilities.hasBacklight && Capabilities.hasBrightnessctl) brightnessQuery.exec(["brightnessctl", "-m"])
        if (advancedAudio && Capabilities.hasAudioSink) streamQuery.exec(["laptopui-audio-streams"])
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
    function parseStreams(text) {
        let streams = []
        try { streams = JSON.parse(text.trim() || "[]") } catch (error) { streams = [] }
        streamModel.clear()
        for (const stream of streams) streamModel.append(stream)
    }

    ListModel { id: streamModel }

    Process { id: sinkQuery; stdout: StdioCollector { onStreamFinished: root.parseVolume(text, false) } }
    Process { id: sourceQuery; stdout: StdioCollector { onStreamFinished: root.parseVolume(text, true) } }
    Process { id: brightnessQuery; stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(","); root.brightness = p.length > 3 ? p[3].trim() : "—"; root.brightnessLevel = p.length > 3 ? Number.parseFloat(p[3]) : 0 } } }
    Process { id: streamQuery; stdout: StdioCollector { onStreamFinished: root.parseStreams(text) } }
    Timer { id: volumeApply; interval: 70; onTriggered: { Quickshell.execDetached(["wpctl", "set-volume", root.pendingVolumeTarget, Math.round(root.pendingVolumeLevel) + "%"]); delayedRefresh.restart() } }
    Timer { id: brightnessApply; interval: 70; onTriggered: root.setBrightness(root.pendingBrightnessLevel) }
    Timer { id: delayedRefresh; interval: 180; onTriggered: root.refresh() }
    Timer { interval: 2000; running: root.open && root.advancedAudio; repeat: true; onTriggered: streamQuery.exec(["laptopui-audio-streams"]) }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            // During close, retain the layer until the card reaches opacity 0.
            visible: (modelData.name === root.targetScreen) && (root.open || card.opacity > 0)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            focusable: true
            Shortcut { enabled: root.open && modelData.name === root.targetScreen; sequence: "Escape"; onActivated: root.closeRequested() }

            MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }

            Rectangle {
                id: card
                width: Math.min(410, parent.width - 28)
                height: Math.min(parent.height - Theme.panelPopupCardTop - 20, controlContents.implicitHeight + 36)
                clip: true
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Theme.panelPopupCardTop
                anchors.rightMargin: Theme.panelPopupRightInset
                radius: Theme.radiusLarge
                color: Theme.popupBackground
                border.color: Theme.border
                border.width: 1
                opacity: root.open ? 1 : 0
                y: root.open ? Theme.panelPopupCardTop : (root.closing ? Theme.panelPopupCardTop + 22 : Theme.panelHeight - 18)
                scale: root.open ? 1 : (root.closing ? 0.84 : 0.9)
                rotation: 0
                transformOrigin: Item.TopRight
                Behavior on opacity { NumberAnimation { duration: SettingsState.reducedMotion ? 0 : (Theme.animationNormal - 20); easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: SettingsState.reducedMotion ? 0 : (Theme.animationNormal + 80); easing.type: Easing.OutBack } }
                Behavior on scale { NumberAnimation { duration: SettingsState.reducedMotion ? 0 : (Theme.animationNormal + 70); easing.type: Easing.OutBack } }
                Behavior on rotation { NumberAnimation { duration: SettingsState.reducedMotion ? 0 : (Theme.animationNormal + 100); easing.type: Easing.OutBack } }

                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.open ? parent.width * 0.54 : 0
                    height: 2
                    radius: height / 2
                    color: Theme.accent
                    opacity: 0.88
                    Behavior on width { NumberAnimation { duration: SettingsState.reducedMotion ? 0 : (Theme.animationNormal + 120); easing.type: Easing.OutCubic } }
                }

                MouseArea { anchors.fill: parent }
                focus: root.open
                Keys.onEscapePressed: root.closeRequested()
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 18
                    contentHeight: controlContents.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                ColumnLayout {
                    id: controlContents
                    width: parent.width
                    spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Control center"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 17; font.bold: true }
                        Item { Layout.fillWidth: true }
                        ActionButton { text: "Close"; onClicked: root.closeRequested() }
                    }
                    StatusStrip { Layout.fillWidth: true; active: root.open }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }
                    Rectangle {
                        visible: Capabilities.hasAudioSink
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 9
                        color: advancedAudioMouse.containsMouse ? Theme.surfaceHover : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            Text { text: "󰓃"; color: root.advancedAudio ? Theme.accent : Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 14 }
                            Text { text: "Application mixer"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: root.advancedAudio }
                            Item { Layout.fillWidth: true }
                            Text { text: root.advancedAudio ? "⌃" : "⌄"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 15 }
                        }
                        MouseArea {
                            id: advancedAudioMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.advancedAudio = !root.advancedAudio
                                if (root.advancedAudio) streamQuery.exec(["laptopui-audio-streams"])
                            }
                        }
                    }
                    Item {
                        visible: root.advancedAudio
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? Math.min(138, Math.max(38, streamModel.count * 46)) : 0
                        clip: true
                        Text {
                            visible: streamModel.count === 0
                            anchors.centerIn: parent
                            text: "No applications are playing audio"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        Flickable {
                            anchors.fill: parent
                            visible: streamModel.count > 0
                            contentHeight: streamColumn.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true
                            Column {
                                id: streamColumn
                                width: parent.width
                                spacing: 0
                                Repeater {
                                    model: streamModel
                                    delegate: ControlRow {
                                        required property string streamId
                                        required property string name
                                        required property real streamLevel
                                        required property bool streamMuted
                                        width: streamColumn.width
                                        icon: streamMuted ? "󰖁" : "󰎆"
                                        title: name
                                        titleWidth: 106
                                        value: Math.round(streamLevel) + "%"
                                        level: streamLevel
                                        muteAvailable: true
                                        muted: streamMuted
                                        muteIcon: streamMuted ? "󰖁" : "󰕾"
                                        onLevelRequested: level => root.queueVolume(streamId, level)
                                        onMuteRequested: root.mute(streamId)
                                    }
                                }
                            }
                        }
                    }
                    ControlRow { visible: Capabilities.hasAudioSink; icon: root.sinkMuted ? "󰖁" : "󰕾"; title: "Volume"; value: root.sinkVolume; level: root.sinkLevel; muted: root.sinkMuted; muteAvailable: true; muteIcon: root.sinkMuted ? "󰖁" : "󰕾"; deviceSelectionAvailable: true; onLevelRequested: level => root.queueVolume("@DEFAULT_AUDIO_SINK@", level); onMuteRequested: root.mute("@DEFAULT_AUDIO_SINK@"); onDeviceSelectionChanged: delayedRefresh.restart() }
                    ControlRow { visible: Capabilities.hasAudioSource; icon: root.sourceMuted ? "󰍭" : "󰍬"; title: "Microphone"; value: root.sourceVolume; level: root.sourceLevel; muted: root.sourceMuted; muteAvailable: true; muteIcon: root.sourceMuted ? "󰍭" : "󰍬"; deviceSelectionAvailable: true; microphone: true; onLevelRequested: level => root.queueVolume("@DEFAULT_AUDIO_SOURCE@", level); onMuteRequested: root.mute("@DEFAULT_AUDIO_SOURCE@"); onDeviceSelectionChanged: delayedRefresh.restart() }
                    ControlRow { visible: Capabilities.hasBacklight && Capabilities.hasBrightnessctl; icon: "󰃠"; title: "Brightness"; value: root.brightness; level: root.brightnessLevel; onLevelRequested: level => root.queueBrightness(level) }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8
                        QuickToggle { Layout.fillWidth: true; Layout.preferredWidth: 0; icon: "󰤨"; label: "Connectivity"; active: !!NetworkState.info.interface; onClicked: SettingsState.connectivityOpen = true }
                        QuickToggle { Layout.fillWidth: true; Layout.preferredWidth: 0; visible: Capabilities.powerProfilesAvailable; icon: "󰂄"; label: root.profile; active: root.profile === "performance"; onClicked: profilePopup.open = !profilePopup.open }
                        QuickToggle { Layout.fillWidth: true; Layout.preferredWidth: 0; icon: "󰏤"; label: SettingsState.calmMode ? "Calm" : "Effects"; active: SettingsState.calmMode; onClicked: SettingsState.toggleCalmMode() }
                        QuickToggle { Layout.fillWidth: true; Layout.preferredWidth: 0; icon: "󰂚"; label: SettingsState.dnd ? "DND" : "Notifications"; active: SettingsState.dnd; onClicked: SettingsState.toggleDnd() }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }
                    ActionButton { Layout.fillWidth: true; text: SettingsState.focusMode ? "Leave focus · restore previous settings" : "Focus · DND + calm mode"; highlighted: SettingsState.focusMode; onClicked: SettingsState.toggleFocusMode() }
                    DisplayControls { Layout.fillWidth: true; active: root.open }
                    ClipboardHistory {
                        id: clipboardHistory
                        expanded: root.clipboardExpanded
                        onExpansionRequested: root.clipboardExpanded = !root.clipboardExpanded
                        onImplicitHeightChanged: root.clipboardHeight = implicitHeight
                    }
                }

                }
                Rectangle {
                    id: profilePopup
                    property bool open: false
                    visible: open
                    width: 190; height: profileColumn.implicitHeight + 16; radius: Theme.radius
                    color: Theme.elevated; border.color: Theme.border; border.width: 1
                    anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 18
                    Column {
                        id: profileColumn
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8; spacing: 2
                        Repeater { model: Capabilities.powerProfiles
                            delegate: QuickMenuItem { required property string modelData; text: modelData; active: root.profile === modelData; onClicked: { Capabilities.setPowerProfile(modelData); profilePopup.open = false; delayedRefresh.restart() } }
                        }
                    }
                }
            }
            onVisibleChanged: {
                if (visible) {
                    root.refresh()
                    clipboardHistory.refresh()
                } else {
                    profilePopup.open = false
                    root.closing = false
                }
            }
        }
    }
}
