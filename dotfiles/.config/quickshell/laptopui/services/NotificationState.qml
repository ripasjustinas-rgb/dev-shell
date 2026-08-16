pragma Singleton

import Quickshell.Services.Notifications
import QtQuick

Item {
    id: root
    property int unreadCount: 0
    property var receivedAt: ({})
    readonly property int maxHistory: 100

    function timeLabel(notification) {
        const stamp = receivedAt[notification.id]
        if (!stamp) return "now"
        const seconds = Math.max(0, Math.floor((Date.now() - stamp) / 1000))
        return seconds < 60 ? "now" : (seconds < 3600 ? Math.floor(seconds / 60) + "m" : Math.floor(seconds / 3600) + "h")
    }
    function clearUnread() { unreadCount = 0 }
    function clearHistory() {
        while (notificationServer.trackedNotifications.count) notificationServer.trackedNotifications.get(0).dismiss()
        clearUnread()
    }

    NotificationServer {
        id: notificationServer
        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: true
        inlineReplySupported: true
        bodySupported: true
        onNotification: function(notification) {
            notification.tracked = true
            root.receivedAt[notification.id] = Date.now()
            while (trackedNotifications.count > root.maxHistory) trackedNotifications.get(0).dismiss()
            root.unreadCount += 1
        }
    }
    property alias server: notificationServer
}
