import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property string palettePath: (Quickshell.env("XDG_STATE_HOME")
        || (Quickshell.env("HOME") + "/.local/state")) + "/laptopui/colors.json"

    function alpha(color, opacity) {
        const value = Qt.color(color)
        return Qt.rgba(value.r, value.g, value.b, opacity)
    }

    FileView {
        id: paletteFile
        path: root.palettePath
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            property string primary: "#dabaf9"
            property string on_primary: "#3e2459"
            property string secondary: "#d0c1da"
            property string surface: "#151218"
            property string surface_variant: "#4a454e"
            property string on_surface: "#e8e0e8"
            property string on_surface_variant: "#ccc4cf"
            property string outline: "#968e98"
            property string error: "#ffb4ab"
            property string tertiary: "#f3b7be"

            onPrimaryChanged: {
                Theme.accent = primary
                Theme.glow = root.alpha(primary, 0.50)
            }
            onOn_primaryChanged: Theme.accentText = on_primary
            onSecondaryChanged: Theme.secondary = secondary
            onSurfaceChanged: {
                Theme.background = root.alpha(surface, 0.84)
                Theme.surface = root.alpha(surface, 0.88)
                Theme.overlay = root.alpha(surface, 0.92)
            }
            onSurface_variantChanged: {
                Theme.elevated = root.alpha(surface_variant, 0.93)
                Theme.surfaceHover = root.alpha(surface_variant, 0.90)
            }
            onOn_surfaceChanged: Theme.text = on_surface
            onOn_surface_variantChanged: Theme.muted = on_surface_variant
            onOutlineChanged: Theme.border = root.alpha(outline, 0.62)
            onErrorChanged: Theme.danger = error
            onTertiaryChanged: Theme.warningColor = tertiary
        }
    }
}
