import QtQuick
import qs.services
import qs.theme

Rectangle {
    id: root

    property string text: ""
    property bool highlighted: false

    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 34
    radius: Theme.radius
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.45
    color: highlighted ? Theme.accent : (mouse.containsMouse || activeFocus ? Theme.surfaceHover : Theme.surface)
    border.width: 1
    border.color: activeFocus ? Theme.accent : Theme.glassBorder
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: {
        if (enabled) {
            clicked();
        }
    }
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.highlighted ? Theme.accentText : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Behavior on color {
        ColorAnimation {
            duration: SettingsState.reducedMotion ? 0 : Theme.animationFast
        }

    }

}
