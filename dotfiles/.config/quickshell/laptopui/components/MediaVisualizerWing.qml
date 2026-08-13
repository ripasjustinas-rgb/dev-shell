import QtQuick
import qs.theme

Item {
    id: root
    property bool active: false
    property bool mirrored: false
    property var spectrumData: []
    property real burstLevel: 0
    property real phase: 0
    property int laneCount: 5
    property int dotSize: 3
    property int dotGap: 2
    property int minDots: 3
    property int maxDots: 14
    readonly property int expandedWidth: maxDots * dotSize + (maxDots - 1) * dotGap

    implicitWidth: active ? expandedWidth : 0
    implicitHeight: Theme.panelContentHeight - 4
    opacity: active ? 1 : 0
    clip: true
    Behavior on implicitWidth { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 180 } }

    Timer {
        running: root.active
        repeat: true
        interval: 60
        onTriggered: root.phase += 0.25
    }

    function laneLevel(lane) {
        if (!spectrumData || spectrumData.length === 0) return 0.12
        const targets = [1, 5, 10, 18, 27]
        const index = Math.min(spectrumData.length - 1, targets[laneCount - lane - 1])
        const value = Number(spectrumData[index])
        return isNaN(value) ? 0 : Math.max(0, Math.min(1, value / 16))
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.laneCount
            Item {
                id: laneItem
                required property int index
                readonly property real level: Math.max(root.laneLevel(index), 0.08 + 0.05 * Math.sin(root.phase + index))
                readonly property int dots: Math.round(root.minDots + (root.maxDots - root.minDots) * level)
                width: root.expandedWidth
                height: root.dotSize

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: root.mirrored ? undefined : parent.left
                    anchors.right: root.mirrored ? parent.right : undefined
                    spacing: root.dotGap
                    Repeater {
                        model: laneItem.dots
                        Rectangle {
                            required property int index
                            readonly property real trail: (index + 1) / Math.max(1, laneItem.dots)
                            width: root.dotSize
                            height: root.dotSize
                            radius: width / 2
                            color: Theme.secondary
                            opacity: Math.min(1, 0.18 + trail * 0.78 + root.burstLevel * 0.18)
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + 5 + root.burstLevel * 4
                                height: parent.height + 5 + root.burstLevel * 4
                                radius: width / 2
                                color: Theme.accent
                                opacity: parent.opacity * (0.2 + root.burstLevel * 0.2)
                                z: -1
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root.burstLevel > 0.12 && laneItem.level > 0.45
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: root.mirrored ? parent.left : undefined
                    anchors.right: root.mirrored ? undefined : parent.right
                    width: root.dotSize + 2
                    height: width
                    radius: width / 2
                    color: Theme.text
                    opacity: Math.min(1, 0.35 + root.burstLevel * 0.75)
                }
            }
        }
    }
}
