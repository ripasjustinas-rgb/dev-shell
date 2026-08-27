import QtQuick
import qs.services

Item {
    property string screenName: ""
    readonly property bool active: VPetState.visibleOn(screenName)

    visible: active
    implicitWidth: active ? VPetState.slotWidth : 0
    implicitHeight: 26
}
