import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

Item {
    id: root
    property bool controlOpen: false
    onControlOpenChanged: SettingsState.controlOpen = controlOpen
    Connections {
        target: SettingsState
        function onOverlayOpened(name) { root.closeOverlays() }
    }
    function toggle(name) {
        const opening = !root[name]
        closeOverlays()
        SettingsState.connectivityOpen = false
        SettingsState.mediaScreen = ""
        if (opening) SettingsState.overlayOpened(name)
        root[name] = opening
    }
    property bool launcherOpen: false
    property bool notificationsOpen: false
    property bool powerOpen: false
    property bool overviewOpen: false
    property bool commandPaletteOpen: false

    function closeOverlays() {
        controlOpen = false
        launcherOpen = false
        notificationsOpen = false
        powerOpen = false
        overviewOpen = false
        commandPaletteOpen = false
    }

    IpcHandler {
        target: "laptopui"
        function toggleControlCenter() { root.toggle("controlOpen") }
        function toggleLauncher() { root.toggle("launcherOpen"); if (root.launcherOpen) launcher.reset() }
        function toggleNotifications() { root.toggle("notificationsOpen") }
        function togglePower() { root.toggle("powerOpen") }
        function toggleOverview() { root.toggle("overviewOpen") }
        function toggleCommandPalette() { root.toggle("commandPaletteOpen") }
        function toggleConnectivity() { SettingsState.connectivityOpen = !SettingsState.connectivityOpen; root.closeOverlays() }
        function uiState(): string { return JSON.stringify({screen: SettingsState.focusedScreen, media: SettingsState.mediaScreen, control: root.controlOpen, connectivity: SettingsState.connectivityOpen}) }
        function toggleMedia() { SettingsState.mediaScreen = SettingsState.mediaScreen.length ? "" : SettingsState.focusedScreen }
        function osd(kind: string) { osd.show(kind) }
        function refreshUpdates() { UpdateState.refresh() }
        function closeOverlays() { root.closeOverlays(); SettingsState.connectivityOpen = false; SettingsState.mediaScreen = "" }
    }

    ConnectivityMenu { requestedOpen: SettingsState.connectivityOpen }
    ControlCenter { open: root.controlOpen; onCloseRequested: root.controlOpen = false }
    AppLauncher { id: launcher; open: root.launcherOpen; onCloseRequested: root.launcherOpen = false }
    NotificationCenter { open: root.notificationsOpen; onCloseRequested: root.notificationsOpen = false }
    PowerDialog { open: root.powerOpen; onCloseRequested: root.powerOpen = false }
    Overview { open: root.overviewOpen; onCloseRequested: root.overviewOpen = false }
    CommandPalette { open: root.commandPaletteOpen; onCloseRequested: root.commandPaletteOpen = false }
    Osd { id: osd }
}
