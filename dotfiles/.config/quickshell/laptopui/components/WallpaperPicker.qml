import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root
    property bool open: false
    property string currentWallpaper: ""
    property var wallpapers: []
    readonly property string helperDir: Quickshell.env("HOME") + "/.local/bin/"

    function fileName(path) {
        const parts = path.split("/")
        return parts[parts.length - 1]
    }

    function refresh() {
        currentReader.exec(["sh", "-c", "cat \"${XDG_STATE_HOME:-$HOME/.local/state}/laptopui/wallpaper\" 2>/dev/null || true"])
        // Keep image paths as process arguments, rather than interpolating
        // them into a shell command when the user makes a selection.
        wallpaperReader.exec(["sh", "-c", "find \"${LAPTOPUI_WALLPAPER_DIR:-$HOME/Wallpapers}\" -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) -print 2>/dev/null | sort"])
    }

    function select(path) {
        if (!path.length) return
        wallpaperSetter.exec([helperDir + "laptopui-wallpaper-set", path])
        currentWallpaper = path
        open = false
    }

    onOpenChanged: if (open) refresh()

    Process {
        id: currentReader
        stdout: StdioCollector { onStreamFinished: root.currentWallpaper = text.trim() }
    }
    Process {
        id: wallpaperReader
        stdout: StdioCollector {
            onStreamFinished: {
                const listed = text.trim()
                root.wallpapers = listed.length ? listed.split("\n") : []
            }
        }
    }
    Process { id: wallpaperSetter }
    Process { id: nextWallpaper }
    Process { id: randomWallpaper }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            focusable: true
            WlrLayershell.namespace: "laptopui-wallpaper-picker"
            Keys.onEscapePressed: root.open = false

            // This must stay below the card: otherwise it accepts every click
            // and makes the picker look as if its actions only dismiss it.
            MouseArea { anchors.fill: parent; z: 0; onClicked: root.open = false }

            Rectangle {
                id: card
                z: 1
                // Use the available screen space for browsing rather than a
                // narrow menu: this is a visual picker, not just an action
                // list. The limits still keep it comfortable on laptops.
                width: Math.min(parent.width - 24, 820)
                height: Math.min(parent.height - Theme.panelHeight - 24, 760)
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: Theme.panelPopupCardTop
                anchors.leftMargin: 12
                radius: Theme.radiusLarge
                color: Theme.background
                border.width: 1
                border.color: Theme.border

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Wallpapers"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 17; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: root.wallpapers.length + " available"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 10 }
                        Text {
                            text: "󰅖"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 16
                            MouseArea { anchors.fill: parent; onClicked: root.open = false }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHover }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: grid.implicitHeight

                        Grid {
                            id: grid
                            width: parent.width
                            columns: Math.max(3, Math.floor(width / 180))
                            spacing: 9

                            Repeater {
                                model: root.wallpapers
                                delegate: Rectangle {
                                    required property string modelData
                                    width: (grid.width - grid.spacing * (grid.columns - 1)) / grid.columns
                                    height: 132
                                    radius: Theme.radius
                                    clip: true
                                    color: Theme.surface
                                    border.width: modelData === root.currentWallpaper ? 2 : 1
                                    border.color: modelData === root.currentWallpaper ? Theme.accent : Theme.border

                                    Image {
                                        anchors.fill: parent
                                        source: "file://" + parent.modelData
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                    }
                                    Rectangle {
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                        height: 26
                                        color: "#b0100d12"
                                        Text {
                                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 7 }
                                            text: root.fileName(parent.modelData)
                                            elide: Text.ElideRight
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                        }
                                    }
                                    Text {
                                        visible: parent.modelData === root.currentWallpaper
                                        anchors { top: parent.top; right: parent.right; margins: 7 }
                                        text: "󰄬"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 16
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: root.select(parent.modelData) }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.wallpapers.length === 0
                        Layout.fillWidth: true
                        text: "No images found in ~/Wallpapers"
                        color: Theme.muted
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 7
                            color: nextMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                            Text { anchors.centerIn: parent; text: "󰒮  Next"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10 }
                            MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { nextWallpaper.exec([root.helperDir + "laptopui-wallpaper-next"]); root.open = false } }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 7
                            color: randomMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                            Text { anchors.centerIn: parent; text: "󰆭  Random"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10 }
                            MouseArea { id: randomMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { randomWallpaper.exec([root.helperDir + "laptopui-wallpaper-random"]); root.open = false } }
                        }
                        Rectangle {
                            Layout.preferredWidth: 78
                            Layout.preferredHeight: 32
                            radius: 7
                            color: refreshMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                            Text { anchors.centerIn: parent; text: "Refresh"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10 }
                            MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.refresh() }
                        }
                    }
                }
            }
        }
    }
}
