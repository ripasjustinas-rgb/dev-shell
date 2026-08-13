import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

Item {
    id: root
    property string location: "Vilnius"
    property string temperature: "--°"
    implicitWidth: clockColumn.implicitWidth
    implicitHeight: Theme.panelContentHeight - 4

    Column {
        id: clockColumn
        anchors.centerIn: parent
        spacing: -1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "ddd, d MMM  HH:mm")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.location + "  " + root.temperature
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 9
        }
    }

    SystemClock { id: clock }

    Process {
        id: weather
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                if (value.length) root.temperature = value
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weather.exec(["curl", "--connect-timeout", "3", "--max-time", "5", "-fsSL", "https://wttr.in/Vilnius?format=%t"])
    }
}
