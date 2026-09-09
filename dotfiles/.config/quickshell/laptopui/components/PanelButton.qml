import QtQuick
import QtQuick.Controls
import qs.theme
import qs.services

Rectangle {
    id: root
    property string label: ""
    property string tooltip: ""
    property color labelColor: Theme.muted
    signal clicked()
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: tooltip || label
    Accessible.onPressAction: clicked()
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    border.width: activeFocus ? 1 : 0
    border.color: Theme.accent
    ToolTip.visible: mouse.containsMouse && tooltip.length > 0
    ToolTip.text: tooltip
    ToolTip.delay: 600
    implicitWidth: Math.max(30, labelText.implicitWidth + 12)
    implicitHeight: 26
    radius: Theme.radius
    color: mouse.containsMouse ? Theme.elevated : Theme.surface
    scale: mouse.pressed ? 0.94 : (mouse.containsMouse ? 1.04 : 1)
    Behavior on color { ColorAnimation { duration: SettingsState.reducedMotion ? 0 : (130)} }
    Behavior on scale { NumberAnimation { duration: SettingsState.reducedMotion ? 0 : (130); easing.type: Easing.OutCubic } }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.labelColor
        font.family: Theme.fontFamily
        font.pixelSize: 15
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
