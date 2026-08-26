import QtQuick
import qs

Item {
    id: root

    property string text: ""

    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.text.toUpperCase()
        color: Theme.text
        font.family: Theme.fontFamily
        font.pointSize: Theme.dialogSmallPointSize
        font.bold: true
        font.letterSpacing: 1.5
    }

    Rectangle {
        anchors.left: label.right
        anchors.right: parent.right
        anchors.leftMargin: Theme.itemPadding
        anchors.verticalCenter: parent.verticalCenter
        height: 1
        color: Theme.surface1
    }
}
