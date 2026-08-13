import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root
    property bool open: false
    signal closeRequested()
    property string sinkVolume: "—"
    property string sourceVolume: "—"
    property string brightness: "—"
    property string profile: "balanced"

    function refresh() {
        sinkQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
        sourceQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"])
        brightnessQuery.exec(["brightnessctl", "-m"])
        profileQuery.exec(["powerprofilesctl", "get"])
    }
    function volume(target, amount) { Quickshell.execDetached(["wpctl", "set-volume", target, amount]); delayedRefresh.restart() }
    function mute(target) { Quickshell.execDetached(["wpctl", "set-mute", target, "toggle"]); delayedRefresh.restart() }
    function setBrightness(amount) { Quickshell.execDetached(["brightnessctl", "set", amount]); delayedRefresh.restart() }

    Process { id: sinkQuery; stdout: StdioCollector { onStreamFinished: { const m = text.match(/Volume:\s+([0-9.]+)/); root.sinkVolume = m ? Math.round(Number(m[1]) * 100) + "%" : "—" } } }
    Process { id: sourceQuery; stdout: StdioCollector { onStreamFinished: { const m = text.match(/Volume:\s+([0-9.]+)/); root.sourceVolume = m ? Math.round(Number(m[1]) * 100) + "%" : "—" } } }
    Process { id: brightnessQuery; stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(","); root.brightness = p.length > 3 ? p[3].trim() : "—" } } }
    Process { id: profileQuery; stdout: StdioCollector { onStreamFinished: { if (text.trim().length) root.profile = text.trim() } } }
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

            MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }

            Rectangle {
                id: card
                width: 390
                height: 470
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
                    ControlRow { icon: "󰕾"; title: "Volume"; value: root.sinkVolume; onDecrease: root.volume("@DEFAULT_AUDIO_SINK@", "5%-"); onIncrease: root.volume("@DEFAULT_AUDIO_SINK@", "5%+"); onToggle: root.mute("@DEFAULT_AUDIO_SINK@") }
                    ControlRow { icon: "󰍬"; title: "Microphone"; value: root.sourceVolume; onDecrease: root.volume("@DEFAULT_AUDIO_SOURCE@", "5%-"); onIncrease: root.volume("@DEFAULT_AUDIO_SOURCE@", "5%+"); onToggle: root.mute("@DEFAULT_AUDIO_SOURCE@") }
                    ControlRow { icon: "󰃠"; title: "Brightness"; value: root.brightness; onDecrease: root.setBrightness("5%-"); onIncrease: root.setBrightness("5%+"); onToggle: root.setBrightness("50%") }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }
                    RowLayout {
                        Layout.fillWidth: true
                        QuickToggle { icon: "󰤨"; label: Networking.wifiEnabled ? "Wi-Fi" : "Wi-Fi off"; active: Networking.wifiEnabled; onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
                        QuickToggle { icon: "󰂄"; label: root.profile; active: root.profile === "performance"; onClicked: profilePopup.open = !profilePopup.open }
                        QuickToggle { icon: "󰏤"; label: "Notifications"; active: false; onClicked: { root.closeRequested(); Quickshell.execDetached(["qs", "-c", "laptopui", "ipc", "call", "laptopui", "toggleNotifications"]) } }
                    }
                    Item { Layout.fillHeight: true }
                    Text { text: "Connected devices and controls update live"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11 }
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
                        Repeater { model: ["performance", "balanced", "power-saver"]
                            delegate: QuickMenuItem { required property string modelData; text: modelData; active: root.profile === modelData; onClicked: { Quickshell.execDetached(["powerprofilesctl", "set", modelData]); profilePopup.open = false; delayedRefresh.restart() } }
                        }
                    }
                }
            }
            onVisibleChanged: if (visible) root.refresh()
        }
    }
}
