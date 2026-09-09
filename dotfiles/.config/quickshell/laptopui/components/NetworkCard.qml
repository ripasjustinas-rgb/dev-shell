import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme

Rectangle {
    id: root

    property bool expanded: false

    function copy(value) {
        copyProcess.exec(["wl-copy", String(value)]);
    }

    implicitHeight: body.implicitHeight + 24
    radius: Theme.radius
    color: Theme.surface
    border.color: Theme.glassBorder
    border.width: 1

    Process {
        id: copyProcess
    }

    ColumnLayout {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: NetworkState.info.connection || "Checking connection…"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: (NetworkState.info.interface || "Offline") + (NetworkState.info.vpn && NetworkState.info.vpn.length ? " · VPN: " + NetworkState.info.vpn.join(", ") : "")
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

            }

            ActionButton {
                text: root.expanded ? "Less" : "Details"
                onClicked: root.expanded = !root.expanded
            }

        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "↓ " + NetworkState.rate(NetworkState.download)
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "↑ " + NetworkState.rate(NetworkState.upload)
                color: Theme.secondary
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.bold: true
            }

        }

        Sparkline {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            samples: NetworkState.downloadHistory
            secondarySamples: NetworkState.uploadHistory
        }

        Text {
            text: "Live traffic · last 60 samples"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 9
        }

        ColumnLayout {
            visible: root.expanded
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [["Local IP", NetworkState.info.address || "Unavailable"], ["Gateway", NetworkState.info.gateway || "Unavailable"], ["DNS", NetworkState.info.dns || "Unavailable"], ["Internet status (IPv4 / IPv6)", NetworkState.info.connectivity || "Not reported"], ["Link speed", NetworkState.info.linkSpeed || "Not reported"], ["Wi-Fi", NetworkState.info.wifi && NetworkState.info.wifi.ssid ? NetworkState.info.wifi.signal + "% · " + NetworkState.info.wifi.frequency + " · channel " + NetworkState.info.wifi.channel + " · " + NetworkState.info.wifi.security : "Not connected"], ["Interface totals", "↓ " + NetworkState.bytes(NetworkState.received) + "  ↑ " + NetworkState.bytes(NetworkState.transmitted)]]

                ColumnLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: modelData[0]
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData[1]
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        wrapMode: Text.WrapAnywhere

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copy(parent.text)
                        }

                    }

                }

            }

            Text {
                Layout.fillWidth: true
                text: "Click a value to copy. Totals are since the interface counter reset. Link speed is separate from internet capacity."
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 9
                wrapMode: Text.Wrap
            }

            RowLayout {
                ActionButton {
                    text: NetworkState.diagnosing ? "Checking…" : "Check connection"
                    enabled: !NetworkState.diagnosing && !NetworkState.testing
                    onClicked: NetworkState.diagnose()
                }

                ActionButton {
                    text: NetworkState.testing ? "Testing…" : "Speed test"
                    enabled: !!NetworkState.info.speedtestAvailable && !NetworkState.testing && !NetworkState.diagnosing
                    onClicked: NetworkState.speedtest()
                }

            }

            Text {
                Layout.fillWidth: true
                text: "Check probes the gateway, DNS and example.com. Speed tests transfer data" + (NetworkState.info.speedtestAvailable ? "." : " and require speedtest-cli.")
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 9
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: NetworkState.result
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: NetworkState.testResult
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 10
                wrapMode: Text.Wrap
            }

        }

    }

}
