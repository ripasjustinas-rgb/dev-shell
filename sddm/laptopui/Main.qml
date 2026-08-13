import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: surface

    readonly property color primary: config.stringValue("Primary") || "#dabaf9"
    readonly property color onPrimary: config.stringValue("OnPrimary") || "#3e2459"
    readonly property color secondary: config.stringValue("Secondary") || "#d0c1da"
    readonly property color surface: config.stringValue("Surface") || "#151218"
    readonly property color surfaceVariant: config.stringValue("SurfaceVariant") || "#4a454e"
    readonly property color foreground: config.stringValue("OnSurface") || "#e8e0e8"
    readonly property color mutedForeground: config.stringValue("OnSurfaceVariant") || "#ccc4cf"
    readonly property color outline: config.stringValue("Outline") || "#968e98"
    readonly property color error: config.stringValue("Error") || "#ffb4ab"
    readonly property string fontFamily: config.stringValue("FontFamily") || "JetBrainsMono Nerd Font"
    property bool authenticating: false
    property string message: ""
    property bool loginFailed: false
    property date now: new Date()

    function alpha(colorValue, opacity) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function tryLogin() {
        if (authenticating || username.text.length === 0) return
        authenticating = true
        loginFailed = false
        message = "Authenticating…"
        sddm.login(username.text, password.text, session.currentIndex)
    }

    Image {
        anchors.fill: parent
        source: config.stringValue("Background") || "background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.alpha(root.surface, 0.42) }
            GradientStop { position: 0.55; color: root.alpha(root.surface, 0.66) }
            GradientStop { position: 1.0; color: root.alpha(root.surface, 0.90) }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: root.alpha(root.foreground, 0.14)
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(460, root.width - 48)
        spacing: 18

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: -4

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(root.now, "HH:mm")
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Math.min(76, root.height * 0.085)
                font.weight: Font.Light
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(root.now, "dddd, d MMMM")
                color: root.mutedForeground
                font.family: root.fontFamily
                font.pixelSize: 14
                font.letterSpacing: 1.2
            }
        }

        Rectangle {
            id: card
            Layout.fillWidth: true
            Layout.preferredHeight: content.implicitHeight + 54
            radius: 26
            color: root.alpha(root.surface, 0.86)
            border.width: 1
            border.color: root.alpha(root.outline, 0.58)

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: parent.radius - 2
                color: "transparent"
                border.width: 1
                border.color: root.alpha(root.foreground, 0.13)
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: parent.width * 0.44
                height: 2
                radius: 1
                color: root.primary
                opacity: 0.78
            }

            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: 26
                spacing: 14

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 58
                    Layout.preferredHeight: 58
                    radius: 20
                    color: root.alpha(root.primary, 0.16)
                    border.width: 1
                    border.color: root.alpha(root.primary, 0.58)

                    Text {
                        anchors.centerIn: parent
                        text: "󰣇"
                        color: root.primary
                        font.family: root.fontFamily
                        font.pixelSize: 30
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Welcome back"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: sddm.hostName
                    color: root.mutedForeground
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }

                QQC2.TextField {
                    id: username
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    text: config.stringValue("DefaultUser") || userModel.lastUser || ""
                    placeholderText: "Username"
                    color: root.foreground
                    placeholderTextColor: root.alpha(root.mutedForeground, 0.70)
                    selectionColor: root.primary
                    selectedTextColor: root.onPrimary
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    leftPadding: 16
                    rightPadding: 16
                    background: Rectangle {
                        radius: 15
                        color: root.alpha(root.surfaceVariant, username.activeFocus ? 0.74 : 0.54)
                        border.width: 1
                        border.color: username.activeFocus ? root.primary : root.alpha(root.outline, 0.48)
                    }
                    KeyNavigation.tab: password
                }

                QQC2.TextField {
                    id: password
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: root.foreground
                    placeholderTextColor: root.alpha(root.mutedForeground, 0.70)
                    selectionColor: root.primary
                    selectedTextColor: root.onPrimary
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    leftPadding: 16
                    rightPadding: 48
                    enabled: !root.authenticating
                    onAccepted: root.tryLogin()
                    background: Rectangle {
                        radius: 15
                        color: root.alpha(root.surfaceVariant, password.activeFocus ? 0.74 : 0.54)
                        border.width: 1
                        border.color: root.loginFailed ? root.error
                            : (password.activeFocus ? root.primary : root.alpha(root.outline, 0.48))
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: keyboard.capsLock ? "󰪛" : "󰌾"
                        color: keyboard.capsLock ? root.primary : root.mutedForeground
                        font.family: root.fontFamily
                        font.pixelSize: 15
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.message.length > 0
                    text: root.message
                    color: root.loginFailed ? root.error : root.mutedForeground
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                QQC2.Button {
                    id: loginButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    enabled: !root.authenticating && username.text.length > 0
                    onClicked: root.tryLogin()

                    contentItem: Row {
                        spacing: 9
                        anchors.centerIn: parent
                        Text {
                            text: root.authenticating ? "󰔟" : "󰌆"
                            color: root.onPrimary
                            font.family: root.fontFamily
                            font.pixelSize: 16
                        }
                        Text {
                            text: root.authenticating ? "Signing in…" : "Enter session"
                            color: root.onPrimary
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    background: Rectangle {
                        radius: 15
                        color: loginButton.enabled
                            ? (loginButton.hovered ? root.secondary : root.primary)
                            : root.alpha(root.primary, 0.35)
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    QQC2.ComboBox {
                        id: session
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        model: sessionModel
                        currentIndex: sessionModel.lastIndex
                        textRole: "name"
                        font.family: root.fontFamily
                        font.pixelSize: 10
                        contentItem: Text {
                            leftPadding: 12
                            rightPadding: 28
                            text: session.displayText
                            color: root.mutedForeground
                            font: session.font
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        background: Rectangle {
                            radius: 13
                            color: root.alpha(root.surfaceVariant, 0.48)
                            border.width: 1
                            border.color: root.alpha(root.outline, 0.40)
                        }
                    }

                    QQC2.Button {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 40
                        onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
                        contentItem: Text {
                            text: keyboard.layouts.length > 0
                                ? keyboard.layouts.get(keyboard.currentLayout).shortName.toUpperCase() : "KB"
                            color: root.mutedForeground
                            font.family: root.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 13
                            color: root.alpha(root.surfaceVariant, 0.48)
                            border.width: 1
                            border.color: root.alpha(root.outline, 0.40)
                        }
                    }
                }
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 10

        Repeater {
            model: [
                { icon: "󰜉", allowed: sddm.canReboot, action: "reboot" },
                { icon: "󰐥", allowed: sddm.canPowerOff, action: "power" }
            ]
            delegate: QQC2.Button {
                required property var modelData
                width: 44
                height: 44
                visible: modelData.allowed
                onClicked: modelData.action === "reboot" ? sddm.reboot() : sddm.powerOff()
                contentItem: Text {
                    text: modelData.icon
                    color: parent.hovered ? root.primary : root.mutedForeground
                    font.family: root.fontFamily
                    font.pixelSize: 17
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 15
                    color: root.alpha(root.surface, parent.hovered ? 0.92 : 0.72)
                    border.width: 1
                    border.color: parent.hovered ? root.primary : root.alpha(root.outline, 0.44)
                }
            }
        }
    }

    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 26
        text: "laptopui  •  secure session"
        color: root.alpha(root.mutedForeground, 0.72)
        font.family: root.fontFamily
        font.pixelSize: 9
        font.letterSpacing: 0.8
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            root.authenticating = true
            root.loginFailed = false
            root.message = "Welcome. Starting Hyprland…"
        }
        function onLoginFailed() {
            root.authenticating = false
            root.loginFailed = true
            root.message = "That did not unlock it. Check the password and try again."
            password.text = ""
            password.forceActiveFocus()
        }
        function onInformationMessage(message) { root.message = message }
    }

    Component.onCompleted: password.forceActiveFocus()
}
