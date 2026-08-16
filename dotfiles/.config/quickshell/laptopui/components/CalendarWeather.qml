import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root
    property Item anchorItem
    property string location: "Vilnius"
    property date displayDate: new Date()
    property var forecast: []
    property bool forecastLoading: false
    property bool requestedOpen: false

    function monthStart() {
        return new Date(displayDate.getFullYear(), displayDate.getMonth(), 1)
    }

    function daysInMonth() {
        return new Date(displayDate.getFullYear(), displayDate.getMonth() + 1, 0).getDate()
    }

    function cellDate(index) {
        const start = monthStart()
        const offset = (start.getDay() + 6) % 7
        return new Date(displayDate.getFullYear(), displayDate.getMonth(), index - offset + 1)
    }

    function isToday(date) {
        const today = new Date()
        return date.getFullYear() === today.getFullYear()
            && date.getMonth() === today.getMonth()
            && date.getDate() === today.getDate()
    }

    function refreshForecast() {
        if (!forecastQuery.running) {
            forecastLoading = true
            forecastQuery.exec([Quickshell.env("HOME") + "/.local/bin/laptopui-weather", "--forecast"])
        }
    }

    function weatherIcon(code) {
        if ([95, 96, 99].indexOf(code) !== -1) return "\ue31d"
        if ([71, 73, 75, 77, 85, 86].indexOf(code) !== -1) return "\ue31a"
        if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].indexOf(code) !== -1) return "\ue318"
        if ([45, 48].indexOf(code) !== -1) return "\ue313"
        if ([1, 2].indexOf(code) !== -1) return "\ue302"
        if (code === 3) return "\ue312"
        if (code === 0) return "\ue30d"
        if ([200, 386, 389, 392, 395].indexOf(code) !== -1) return "\ue31d"
        if ([179, 182, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371].indexOf(code) !== -1) return "\ue31a"
        if ([176, 185, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 353, 356, 359].indexOf(code) !== -1) return "\ue318"
        if ([143, 248, 260].indexOf(code) !== -1) return "\ue313"
        if (code === 116) return "\ue302"
        if (code === 119 || code === 122) return "\ue312"
        if (code === 113) return "\ue30d"
        return "\ue33d"
    }

    onRequestedOpenChanged: if (requestedOpen) refreshForecast()

    Process {
        id: forecastQuery
        stdout: StdioCollector {
            onStreamFinished: {
                root.forecastLoading = false
                try {
                    const parsed = JSON.parse(text.trim())
                    root.forecast = Array.isArray(parsed) ? parsed : []
                } catch (_) {
                    root.forecast = []
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.requestedOpen || card.opacity > 0
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            focusable: true
            anchors { top: true; bottom: true; left: true; right: true }
            Shortcut { enabled: root.requestedOpen; sequence: "Escape"; onActivated: root.requestedOpen = false }
            MouseArea { anchors.fill: parent; onClicked: root.requestedOpen = false }

    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 640
        height: implicitHeight
        anchors.topMargin: Theme.panelPopupCardTop
        implicitHeight: 380
        radius: Theme.radiusLarge
        color: Theme.background
        border.width: 1
        border.color: Theme.border
        opacity: root.requestedOpen ? 1 : 0
        // The close has its own direction: it folds away instead of merely
        // playing the opening pose backwards.
        scale: root.requestedOpen ? 1 : 0.91
        rotation: root.requestedOpen ? 0 : -1.3
        transformOrigin: Item.Top
        focus: root.requestedOpen
        Keys.onEscapePressed: root.requestedOpen = false
        MouseArea { anchors.fill: parent }
        Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.animationNormal + 60; easing.type: Easing.OutBack } }
        Behavior on rotation { NumberAnimation { duration: Theme.animationNormal + 80; easing.type: Easing.OutBack } }

        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 9
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.requestedOpen ? parent.width * 0.44 : 0
            height: 2
            radius: height / 2
            color: Theme.accent
            opacity: 0.85
            Behavior on width { NumberAnimation { duration: Theme.animationNormal + 110; easing.type: Easing.OutCubic } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 22
            layoutDirection: Qt.RightToLeft

            ColumnLayout {
                Layout.preferredWidth: 332
                Layout.fillHeight: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: Qt.formatDate(root.displayDate, Qt.locale("en_US"), "MMMM yyyy")
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "‹"
                        color: previous.containsMouse ? Theme.accent : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 24
                        MouseArea { id: previous; anchors.fill: parent; hoverEnabled: true; onClicked: root.displayDate = new Date(root.displayDate.getFullYear(), root.displayDate.getMonth() - 1, 1) }
                    }
                    Text {
                        text: "›"
                        color: next.containsMouse ? Theme.accent : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 24
                        MouseArea { id: next; anchors.fill: parent; hoverEnabled: true; onClicked: root.displayDate = new Date(root.displayDate.getFullYear(), root.displayDate.getMonth() + 1, 1) }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 3
                    rowSpacing: 4
                    Repeater {
                        model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                        delegate: Text {
                            required property string modelData
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 23
                            text: modelData
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                    Repeater {
                        model: 42
                        delegate: Rectangle {
                            required property int index
                            readonly property date dateValue: root.cellDate(index)
                            readonly property bool inCurrentMonth: dateValue.getMonth() === root.displayDate.getMonth()
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 38
                            radius: 10
                            color: root.isToday(dateValue) ? Theme.accent : (dayMouse.containsMouse ? Theme.surfaceHover : "transparent")
                            Text {
                                anchors.centerIn: parent
                                text: parent.dateValue.getDate()
                                color: root.isToday(parent.dateValue) ? Theme.accentText : (parent.inCurrentMonth ? Theme.text : Theme.muted)
                                opacity: parent.inCurrentMonth || root.isToday(parent.dateValue) ? 1 : 0.45
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: root.isToday(parent.dateValue)
                            }
                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.displayDate = new Date(parent.dateValue)
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: Theme.surfaceHover }

            ColumnLayout {
                Layout.preferredWidth: 230
                Layout.fillHeight: true
                spacing: 10
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Weather forecast"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 18; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "↻"
                        color: refreshMouse.containsMouse ? Theme.accent : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                        MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.refreshForecast() }
                    }
                }
                Text { text: root.location + " · next 5 days"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Item { Layout.fillHeight: true; visible: root.forecast.length === 0 }
                Text {
                    Layout.fillWidth: true
                    visible: root.forecast.length === 0
                    text: root.forecastLoading ? "Loading weather data…" : "Forecast is currently unavailable"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
                Repeater {
                    model: root.forecast
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 11
                        color: Theme.surface
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8
                            Text { text: root.weatherIcon(modelData.code); color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 22 }
                            Text {
                                Layout.fillWidth: true
                                text: Qt.formatDate(new Date(modelData.date + "T12:00:00"), Qt.locale("en_US"), "ddd, MMMM d")
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text { text: modelData.min + "° / " + modelData.max + "°"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10 }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }
        }
    }
}
