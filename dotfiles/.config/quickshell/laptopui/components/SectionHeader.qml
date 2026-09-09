import QtQuick
import QtQuick.Layouts
import qs.theme

ActionButton {
    id: root

    property string title: ""
    property string summary: ""
    property bool expanded: false

    text: ""
    Accessible.name: title + (expanded ? ", expanded" : ", collapsed")
    implicitHeight: 36

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10

        Text {
            text: root.title
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
        }

        Text {
            Layout.fillWidth: true
            text: root.summary
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 10
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
        }

        Text {
            text: root.expanded ? "−" : "+"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 14
        }

    }

}
