import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property bool controlOpen: false
    property bool launcherOpen: false
    property bool notificationsOpen: false
    property bool powerOpen: false

    function closeOverlays() {
        controlOpen = false
        launcherOpen = false
        notificationsOpen = false
        powerOpen = false
    }

    IpcHandler {
        target: "laptopui"
        function toggleControlCenter() { root.controlOpen = !root.controlOpen; root.launcherOpen = false; root.notificationsOpen = false }
        function toggleLauncher() {
            const opening = !root.launcherOpen
            root.launcherOpen = opening
            root.controlOpen = false
            root.notificationsOpen = false
            if (opening) launcher.reset()
        }
        function toggleNotifications() { root.notificationsOpen = !root.notificationsOpen; root.controlOpen = false; root.launcherOpen = false }
        function togglePower() { root.powerOpen = !root.powerOpen; root.controlOpen = false; root.launcherOpen = false; root.notificationsOpen = false }
        function osd(kind: string) { osd.show(kind) }
        function closeOverlays() { root.closeOverlays() }
    }

    ControlCenter { open: root.controlOpen; onCloseRequested: root.controlOpen = false }
    AppLauncher { id: launcher; open: root.launcherOpen; onCloseRequested: root.launcherOpen = false }
    NotificationCenter { open: root.notificationsOpen; onCloseRequested: root.notificationsOpen = false }
    PowerDialog { open: root.powerOpen; onCloseRequested: root.powerOpen = false }
    Osd { id: osd }
}
