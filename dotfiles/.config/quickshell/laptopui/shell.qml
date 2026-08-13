//@ pragma ShellId laptopui
//@ pragma IconTheme hicolor

import Quickshell
import QtQuick
import qs.components
import qs.theme

ShellRoot {
    Component.onCompleted: Quickshell.execDetached(["laptopui-theme-generate", "--current"])
    ThemeLoader {}
    Wallpaper {}
    Panel {}
    Dashboard {}
}
