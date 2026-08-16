import QtQuick
import Quickshell.Services.Notifications
pragma Singleton

Item {
    id: root

    property int unreadCount: 0
    property var receivedAt: ({
    })
    readonly property int maxHistory: 100
    property alias server: notificationServer

    function timeLabel(notification) {
        const stamp = receivedAt[notification.id];
        if (!stamp)
            return "now";

        const seconds = Math.max(0, Math.floor((Date.now() - stamp) / 1000));
        return seconds < 60 ? "now" : (seconds < 3600 ? Math.floor(seconds / 60) + "m" : Math.floor(seconds / 3600) + "h");
    }

    function clearUnread() {
        unreadCount = 0;
    }

    function clearHistory() {
        // trackedNotifications is an UntypedObjectModel. Use a snapshot so
        // asynchronous dismissal cannot modify the collection mid-iteration.
        const notifications = notificationServer.trackedNotifications.values.slice();
        for (const notification of notifications) notification.dismiss()
        clearUnread();
    }

    NotificationServer {
        id: notificationServer

        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        onNotification: function(notification) {
            notification.tracked = true;
            root.receivedAt[notification.id] = Date.now();
            const history = trackedNotifications.values;
            while (history.length > root.maxHistory)history[0].dismiss()
            root.unreadCount += 1;
        }
    }

}
