import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.theme

Item {
    id: root

    property bool open: false

    signal closeRequested()

    onOpenChanged: {
        if (open)
            NotificationState.clearUnread();

    }

    Connections {
        function onNotification(notification) {
            if (!SettingsState.dnd && !notification.transient)
                toast.show(notification);

        }

        target: NotificationState.server
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: root.open
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            focusable: true
            Keys.onEscapePressed: root.closeRequested()

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeRequested()
            }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Theme.panelHeight + 14
                anchors.rightMargin: 14
                width: 390
                height: 520
                radius: Theme.radiusLarge
                color: Theme.background
                border.color: Theme.glassBorder
                border.width: 1
                opacity: root.open ? 1 : 0
                clip: true

                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Notifications"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 17
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        QuickToggle {
                            width: 62
                            height: 36
                            icon: SettingsState.dnd ? "󰂛" : "󰂚"
                            label: "DND"
                            active: SettingsState.dnd
                            onClicked: SettingsState.toggleDnd()
                        }

                        Rectangle {
                            Layout.preferredWidth: clearText.implicitWidth + 16
                            Layout.preferredHeight: 28
                            radius: 9
                            color: clearArea.containsMouse ? Theme.surfaceHover : Theme.elevated

                            Text {
                                id: clearText

                                anchors.centerIn: parent
                                text: "Clear all"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                id: clearArea

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: NotificationState.clearHistory()
                            }

                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.surfaceHover
                    }

                    ListView {
                        id: history

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8
                        clip: true
                        model: NotificationState.server.trackedNotifications
                        section.property: "appName"
                        section.criteria: ViewSection.FullString

                        section.delegate: Text {
                            text: section
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            padding: 4
                        }

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool hasActions: modelData.actions && modelData.actions.length > 0

                            width: history.width
                            height: hasActions ? 132 : 104
                            radius: Theme.radius
                            color: cardArea.containsMouse ? Theme.elevated : Theme.surface
                            border.color: cardArea.containsMouse ? Theme.glassHighlight : Theme.glassBorder
                            border.width: 1
                            clip: true

                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 3
                                color: Theme.accent
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                anchors.leftMargin: 16
                                anchors.rightMargin: 34
                                spacing: 10

                                Rectangle {
                                    Layout.alignment: Qt.AlignTop
                                    width: 32
                                    height: 32
                                    radius: 10
                                    color: Theme.elevated
                                    border.color: Theme.glassBorder
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.appName ? modelData.appName.charAt(0).toUpperCase() : "◆"
                                        color: Theme.accent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        font.bold: true
                                    }

                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.appName || "System"
                                            color: Theme.accent
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: NotificationState.timeLabel(modelData)
                                            color: Theme.muted
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                        }

                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.summary
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        text: modelData.body
                                        color: Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: hasActions ? 2 : 3
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignTop
                                    }

                                    Row {
                                        visible: hasActions
                                        spacing: 6

                                        Repeater {
                                            model: modelData.actions

                                            delegate: Rectangle {
                                                required property var modelData

                                                width: actionText.implicitWidth + 16
                                                height: 24
                                                radius: 8
                                                color: actionArea.containsMouse ? Theme.surfaceHover : Theme.elevated
                                                border.color: Theme.glassBorder
                                                border.width: 1

                                                Text {
                                                    id: actionText

                                                    anchors.centerIn: parent
                                                    text: modelData.text
                                                    color: Theme.accent
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    id: actionArea

                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: modelData.invoke()
                                                }

                                            }

                                        }

                                    }

                                }

                            }

                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 7
                                width: 22
                                height: 22
                                radius: 7
                                color: dismissArea.containsMouse ? Theme.surfaceHover : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: dismissArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: modelData.dismiss()
                                }

                            }

                            MouseArea {
                                id: cardArea

                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.animationFast
                                }

                            }

                        }

                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animationFast
                    }

                }

            }

        }

    }

    Toast {
        id: toast
    }

}
