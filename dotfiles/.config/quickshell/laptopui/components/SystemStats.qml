import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root
    property real cpuUsage: 0
    property real previousIdle: 0
    property real previousTotal: 0
    property real ramUsed: 0
    property real ramTotal: 0
    readonly property int ramPercent: ramTotal > 0 ? Math.round(ramUsed / ramTotal * 100) : 0
    implicitWidth: statsRow.implicitWidth
    implicitHeight: Theme.panelContentHeight - 6

    RowLayout {
        id: statsRow
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: [
                { icon: "󰍛", value: Math.round(root.cpuUsage) + "%" },
                { icon: "󰘚", value: root.ramPercent + "%" }
            ]
            Rectangle {
                required property var modelData
                Layout.preferredWidth: 70
                Layout.fillHeight: true
                radius: Theme.radius
                color: statsMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                border.width: 1
                border.color: Theme.glassBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 7
                    anchors.rightMargin: 7
                    spacing: 5

                    Text {
                        Layout.preferredWidth: 20
                        Layout.fillHeight: true
                        text: modelData.icon
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: modelData.value
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MouseArea {
                    id: statsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["kitty", "btop"])
                }
            }
        }
    }

    FileView { id: cpuFile; path: "/proc/stat"; watchChanges: false }
    FileView { id: memoryFile; path: "/proc/meminfo"; watchChanges: false }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { cpuFile.reload(); memoryFile.reload() }
    }
    Connections {
        target: cpuFile
        function onLoaded() {
            const values = cpuFile.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = values[3] + values[4]
            const total = values.reduce((sum, value) => sum + value, 0)
            const delta = total - root.previousTotal
            if (delta > 0) root.cpuUsage = 100 * (1 - (idle - root.previousIdle) / delta)
            root.previousIdle = idle
            root.previousTotal = total
        }
    }
    Connections {
        target: memoryFile
        function onLoaded() {
            const lines = memoryFile.text().split("\n")
            function valueFor(key) {
                const line = lines.find(line => line.startsWith(key))
                return line ? parseInt(line.split(/\s+/)[1]) : 0
            }
            root.ramTotal = valueFor("MemTotal:")
            root.ramUsed = root.ramTotal - valueFor("MemAvailable:")
        }
    }
}
