import QtQuick
import qs.theme
import qs.services

Rectangle {
    id: root
    property string text: ""
    signal clicked()
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: clicked()
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    border.width: 1
    border.color: activeFocus ? Theme.accent : Theme.glassBorder
    width: 25; height: 25; radius: 7
    color: mouse.containsMouse ? Theme.surfaceHover : Theme.surface
    Behavior on color { ColorAnimation { duration: SettingsState.reducedMotion ? 0 : (120)} }
    Text { anchors.centerIn: parent; text: root.text; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13 }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
