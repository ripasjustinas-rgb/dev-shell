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
    property var receivedAt: ({})
    signal closeRequested()
    function timeLabel(notification) {
        const stamp = receivedAt[notification.id]
        if (!stamp) return "now"
        const seconds = Math.max(0, Math.floor((Date.now() - stamp) / 1000))
        return seconds < 60 ? "now" : (seconds < 3600 ? Math.floor(seconds / 60) + "m" : Math.floor(seconds / 3600) + "h")
    }
    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: true
        inlineReplySupported: true
        bodySupported: true
        onNotification: function(notification) {
            notification.tracked = true
            root.receivedAt[notification.id] = Date.now()
            while (server.trackedNotifications.count > 99) server.trackedNotifications.get(0).dismiss()
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
                        section.property: "appName"
                        section.criteria: ViewSection.FullString
                        section.delegate: Text { text: section; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true; padding: 4 }
                        delegate: Rectangle { required property var modelData; width: history.width; height: actionList.count > 0 ? 104 : 76; radius: 11; color: Theme.surface
                            Column { anchors.fill: parent; anchors.margins: 11; spacing: 4
                                Text { text: (modelData.appName || "System") + " · " + root.timeLabel(modelData); color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 10 }
                                Text { text: modelData.summary; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width }
                                Text { text: modelData.body; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                                Row { id: actionList; spacing: 7; Repeater { model: modelData.actions; delegate: Rectangle { required property var modelData; width: actionText.implicitWidth + 14; height: 21; radius: 7; color: Theme.elevated; Text { id: actionText; anchors.centerIn: parent; text: modelData.text; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 10 } MouseArea { anchors.fill: parent; onClicked: modelData.invoke() } } } }
                            }
                            Text { anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8; text: "󰅖"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 12; MouseArea { anchors.fill: parent; onClicked: modelData.dismiss() } }
                        }
                    }
                }
            }
        }
    }
    Toast { id: toast }
}
