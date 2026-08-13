import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

Item {
    id: root
    property string location: "Vilnius"
    property string temperature: "--°"
    property int weatherCode: 0
    property int windSpeed: 0
    property string weatherDescription: "Weather unavailable"
    implicitWidth: weatherRow.implicitWidth
    implicitHeight: Theme.panelContentHeight - 4

    function refreshWeather() {
        if (!weather.running)
            weather.exec([Quickshell.env("HOME") + "/.local/bin/laptopui-weather"])
    }

    function weatherIcon(code, wind, date) {
        const night = date.getHours() < 6 || date.getHours() >= 21
        if ([200, 386, 389, 392, 395].indexOf(code) !== -1) return "\ue31d" // thunderstorm
        if ([179, 182, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338,
             350, 362, 365, 368, 371].indexOf(code) !== -1) return "\ue31a" // snow/sleet
        if ([176, 185, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308,
             311, 314, 353, 356, 359].indexOf(code) !== -1) return "\ue318" // rain/drizzle
        if ([143, 248, 260].indexOf(code) !== -1) return "\ue313" // mist/fog
        if (wind >= 30) return "\ue34b" // strong wind
        if (code === 116) return night ? "\ue37e" : "\ue302" // partly cloudy
        if (code === 119 || code === 122) return "\ue312" // cloudy/overcast
        if (code === 113) return night ? "\ue32b" : "\ue30d" // clear
        return "\ue33d" // fallback thermometer
    }

    Row {
        id: weatherRow
        anchors.centerIn: parent
        height: root.implicitHeight
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.weatherIcon(root.weatherCode, root.windSpeed, clock.date)
            color: root.weatherCode === 0 ? Theme.muted : Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelContentHeight - 6
            renderType: Text.NativeRendering

            Behavior on color { ColorAnimation { duration: 180 } }
        }

        Column {
            id: clockColumn
            anchors.verticalCenter: parent.verticalCenter
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
    }

    SystemClock { id: clock }

    Component.onCompleted: root.refreshWeather()

    Process {
        id: weather
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                if (!value.length) return
                const fields = value.split("\t")
                if (fields.length < 4) return
                const nextCode = parseInt(fields[0])
                const nextTemperature = parseInt(fields[1])
                const nextWind = parseInt(fields[2])
                if (isNaN(nextCode) || isNaN(nextTemperature) || isNaN(nextWind)) return
                root.weatherCode = nextCode
                root.temperature = nextTemperature + "°"
                root.windSpeed = nextWind
                root.weatherDescription = fields.slice(3).join(" ")
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refreshWeather()
    }
}
