import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root
    property var entries: []
    property string status: ""
    signal historySizeChanged(int size)
    Layout.fillWidth: true
    readonly property int visibleEntryCount: Math.min(entries.length, 8)
    readonly property int listHeight: entries.reduce((total, entry) => total + entry.height, 0)
        + Math.max(0, visibleEntryCount - 1) * 4
    implicitHeight: visibleEntryCount > 0 ? 27 + listHeight : 45

    function refresh() {
        listQuery.exec(["cliphist", "list"])
    }

    function parseEntries(text) {
        const lines = text.trim().split("\n").filter(line => line.length)
        entries = lines.slice(0, 8).map(line => {
            const separator = line.indexOf("\t")
            return {
                id: separator >= 0 ? line.slice(0, separator) : line,
                preview: separator >= 0 ? line.slice(separator + 1) : line,
                image: (separator >= 0 ? line.slice(separator + 1) : line).startsWith("[[ binary data"),
                height: (separator >= 0 ? line.slice(separator + 1) : line).startsWith("[[ binary data") ? 68 : 34
            }
        }).filter(entry => /^[0-9]+$/.test(entry.id))
        historySizeChanged(entries.length)
    }

    function copy(entry) {
        status = "Copied"
        copyEntry.exec(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", entry.id])
    }

    Process {
        id: listQuery
        stdout: StdioCollector {
            onStreamFinished: root.parseEntries(text)
        }
    }
    Process {
        id: copyEntry
        onExited: statusTimer.restart()
    }
    Process {
        id: wipeHistory
        onExited: {
            root.status = "Cleared"
            root.entries = []
            root.historySizeChanged(0)
            statusTimer.restart()
        }
    }
    Timer {
        id: statusTimer
        interval: 1400
        onTriggered: root.status = ""
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Clipboard history"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
            }
            Text {
                text: root.status || (root.entries.length ? root.entries.length + " saved" : "")
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: root.entries.length > 0
                text: "Clear"
                color: clearMouse.containsMouse ? Theme.accent : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: wipeHistory.exec(["cliphist", "wipe"])
                }
            }
        }

        ListView {
            id: historyList
            Layout.fillWidth: true
            Layout.preferredHeight: root.listHeight
            Layout.maximumHeight: root.listHeight
            clip: true
            spacing: 4
            model: root.entries
            delegate: Rectangle {
                required property var modelData
                width: historyList.width
                height: modelData.height
                radius: 9
                color: entryMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                Text {
                    visible: !modelData.image
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    text: modelData.preview
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                Rectangle {
                    id: imagePreview
                    visible: modelData.image
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 6
                    clip: true
                    color: Theme.elevated

                        property bool previewReady: false
                        property string previewPath: (Quickshell.env("XDG_RUNTIME_DIR")
                            || "/tmp/laptopui-" + Quickshell.env("USER"))
                        + "/laptopui-clipboard/" + modelData.id + ".png"

                    Image {
                        anchors.fill: parent
                        source: parent.previewReady ? "file://" + parent.previewPath : ""
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        asynchronous: true
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !parent.previewReady
                        text: "󰋩"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                    }
                    Process {
                        id: previewWriter
                        onExited: imagePreview.previewReady = true
                    }
                    Component.onCompleted: {
                        if (modelData.image) previewWriter.exec([
                            Quickshell.env("HOME") + "/.local/bin/laptopui-clipboard-preview",
                            modelData.id
                        ])
                    }
                }
                MouseArea {
                    id: entryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.copy(modelData)
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.entries.length === 0
            text: "Copy text or an image to start a history."
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }
}
