import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root
    property var notification: null
    property bool visibleToast: false
    function show(value) { notification = value; visibleToast = true; hide.restart() }
    Timer { id: hide; interval: 5000; onTriggered: root.visibleToast = false }
    Variants { model: Quickshell.screens
        PanelWindow { required property var modelData; screen: modelData; visible: root.visibleToast; implicitWidth: 360; implicitHeight: 112; color: "transparent"; exclusionMode: ExclusionMode.Ignore; anchors { top: true; right: true }
            Rectangle { anchors.fill: parent; anchors.margins: 10; radius: 16; color: Theme.background; border.color: Theme.border; border.width: 1; opacity: root.visibleToast ? 1 : 0; x: root.visibleToast ? 0 : 30
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Column { anchors.fill: parent; anchors.margins: 13; spacing: 4
                    Text { text: root.notification ? (root.notification.appName || "System") : ""; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    Text { text: root.notification ? root.notification.summary : ""; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13; width: parent.width; elide: Text.ElideRight }
                    Text { text: root.notification ? root.notification.body : ""; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10; width: parent.width; elide: Text.ElideRight }
                }
                MouseArea { anchors.fill: parent; onClicked: { if (root.notification) root.notification.dismiss(); root.visibleToast = false } }
            }
        }
    }
}
