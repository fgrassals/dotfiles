import QtQuick
import qs

Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string detail: ""
    property bool secured: false
    property bool active: false
    property bool focused: false
    property bool dimmed: false

    signal picked

    implicitHeight: Theme.bluetoothRowHeight
    color: focused ? Theme.surface1 : "transparent"
    border.width: 1
    border.color: focused ? Theme.blue : "transparent"

    MouseArea {
        anchors.fill: parent
        enabled: !root.dimmed
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.itemPadding
        anchors.rightMargin: Theme.itemPadding
        spacing: Theme.itemPadding

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.dimmed ? Theme.muted : root.active ? Theme.blue : Theme.text
            font.family: Theme.fontFamily
            font.pointSize: Theme.menuFontPointSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 120
            text: root.title
            color: root.dimmed ? Theme.muted : root.active ? Theme.blue : Theme.text
            font.family: Theme.fontFamily
            font.pointSize: Theme.dialogSmallPointSize
            font.bold: root.active
            font.italic: root.dimmed
            elide: Text.ElideRight
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.secured
            text: "󰌾"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pointSize: Theme.dialogSmallPointSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.detail
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pointSize: Theme.dialogSmallPointSize
        }
    }
}
