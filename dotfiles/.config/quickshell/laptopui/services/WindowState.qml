pragma Singleton

import Quickshell.Hyprland
import QtQuick

Item {
    // Hyprland's live object model updates on compositor events, so overview
    // and workspace UI never need a hyprctl polling loop.
    readonly property var workspaces: Hyprland.workspaces
    function workspace(id) {
        for (const candidate of Hyprland.workspaces.values) if (candidate.id === id) return candidate
        return null
    }
}
