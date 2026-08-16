import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme

Item {
    id: root

    property var toasts: []

    function show(notification) {
        const toast = {
            "key": notification.id + "-" + Date.now(),
            "notification": notification
        };
        toasts = toasts.concat([toast]);
    }

    function dismiss(key) {
        toasts = toasts.filter((toast) => {
            return toast.key !== key;
        });
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: root.toasts.length > 0
            implicitWidth: 390
            implicitHeight: root.toasts.length * 130 + 24
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                right: true
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Repeater {
                    model: root.toasts

                    delegate: Rectangle {
                        required property var modelData

                        width: parent.width
                        height: 122
                        radius: Theme.radiusLarge
                        color: Theme.surface
                        border.color: Theme.glassBorder
                        border.width: 1
                        clip: true

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 4
                            color: Theme.accent
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            anchors.rightMargin: 18
                            spacing: 11

                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 2
                                width: 34
                                height: 34
                                radius: 11
                                color: Theme.elevated
                                border.color: Theme.glassBorder
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.notification.appName ? modelData.notification.appName.charAt(0).toUpperCase() : "◆"
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.notification.appName || "System"
                                        color: Theme.accent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "now"
                                        color: Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }

                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.notification.summary
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: modelData.notification.body
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignTop
                                }

                            }

                        }

                        Timer {
                            id: hide

                            interval: 5000
                            running: true
                            onTriggered: root.dismiss(modelData.key)
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                modelData.notification.dismiss();
                                root.dismiss(modelData.key);
                            }
                            onEntered: hide.stop()
                            onExited: hide.restart()
                        }

                    }

                }

            }

        }

    }

}
