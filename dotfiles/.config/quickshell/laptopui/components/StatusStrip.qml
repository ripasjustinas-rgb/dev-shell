import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.services
import qs.theme

ColumnLayout {
    id: root

    property bool active: false

    spacing: 8

    RowLayout {
        Layout.fillWidth: true

        Repeater {
            model: ["CPU " + Math.round(SystemHealth.cpuUsage) + "%", "RAM " + SystemHealth.ramPercent + "%"]

            Text {
                required property string modelData

                Layout.fillWidth: true
                text: modelData
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }

        }

        Text {
            visible: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
            text: Math.round(UPower.displayDevice.percentage * 100) + "%" + (UPower.displayDevice.timeToEmpty > 0 ? " · " + Math.floor(UPower.displayDevice.timeToEmpty / 3600) + "h " + Math.floor(UPower.displayDevice.timeToEmpty / 60) % 60 + "m" : UPower.onBattery ? "" : " · charging")
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }

    }

    ActionButton {
        Layout.fillWidth: true
        text: "↓ " + NetworkState.rate(NetworkState.download) + "   ↑ " + NetworkState.rate(NetworkState.upload) + "   · Network"
        onClicked: SettingsState.connectivityOpen = true
    }

}
