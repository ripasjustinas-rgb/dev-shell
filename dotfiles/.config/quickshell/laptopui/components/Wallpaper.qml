import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Item {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            screen: modelData
            exclusiveZone: -1
            color: "#0b0d14"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "laptopui-wallpaper"
            WlrLayershell.focusable: false

            function setWallpaper(path) {
                if (!path.length || incoming.source.toString() === "file://" + path || displayed.source.toString() === "file://" + path)
                    return
                incoming.source = "file://" + path
            }

            Image {
                id: displayed
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }

            Image {
                id: incoming
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                opacity: 0

                onStatusChanged: {
                    if (status !== Image.Ready)
                        return
                    if (!displayed.source.toString().length) {
                        displayed.source = incoming.source
                        incoming.opacity = 0
                    } else {
                        fade.start()
                    }
                }
            }

            ParallelAnimation {
                id: fade
                NumberAnimation { target: displayed; property: "opacity"; to: 0; duration: 180 }
                NumberAnimation { target: incoming; property: "opacity"; to: 1; duration: 180 }
                onFinished: {
                    displayed.source = incoming.source
                    displayed.opacity = 1
                    incoming.opacity = 0
                }
            }

            Process {
                id: stateReader
                stdout: StdioCollector {
                    onStreamFinished: root.setWallpaper(text.trim())
                }
            }

            Timer {
                interval: 250
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: stateReader.exec(["sh", "-c", "cat \"$HOME/.local/state/laptopui/wallpaper\" 2>/dev/null || true"])
            }
        }
    }
}
