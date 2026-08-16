import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Item {
    id: root
    property bool open: false
    property bool dnd: SettingsState.dnd
    signal closeRequested()
    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        onNotification: function(notification) {
            notification.tracked = true
            if (!root.dnd && !notification.transient) toast.show(notification)
        }
    }

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
                anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: Theme.panelHeight + 14; anchors.rightMargin: 14
                width: 370; height: 500; radius: 20; color: Theme.background; border.color: Theme.border; border.width: 1
                opacity: root.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                MouseArea { anchors.fill: parent }
                ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 10
                    RowLayout { Layout.fillWidth: true
                        Text { text: "Notifications"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 17; font.bold: true }
                        Item { Layout.fillWidth: true }
                        QuickToggle { width: 62; height: 36; icon: SettingsState.dnd ? "󰂛" : "󰂚"; label: "DND"; active: SettingsState.dnd; onClicked: SettingsState.toggleDnd() }
                        Text { text: "Clear"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 11; MouseArea { anchors.fill: parent; onClicked: server.trackedNotifications.forEach(notification => notification.dismiss()) } }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }
                    ListView { id: history; Layout.fillWidth: true; Layout.fillHeight: true; spacing: 7; clip: true; model: server.trackedNotifications
                        delegate: Rectangle { required property var modelData; width: history.width; height: 76; radius: 11; color: Theme.surface
                            Column { anchors.fill: parent; anchors.margins: 11; spacing: 4
                                Text { text: (modelData.appName || "System") + " · now"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 10 }
                                Text { text: modelData.summary; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width }
                                Text { text: modelData.body; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                            }
                            MouseArea { anchors.fill: parent; onClicked: modelData.dismiss() }
                        }
                    }
                }
            }
        }
    }
    Toast { id: toast }
}
