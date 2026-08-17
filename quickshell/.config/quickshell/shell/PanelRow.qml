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

    implicitHeight: Theme.rowHeight
    color: focused ? Theme.surface1 : "transparent"
    border.width: 1
    border.color: focused ? Theme.blue : "transparent"

    MouseArea {
        anchors.fill: parent
        enabled: !root.dimmed
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }

    // A long detail shortens the title rather than overflowing the row.
    Text {
        id: iconLabel
        anchors.left: parent.left
        anchors.leftMargin: Theme.itemPadding
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.dimmed ? Theme.muted : root.active ? Theme.blue : Theme.text
        font.family: Theme.fontFamily
        font.pointSize: Theme.menuFontPointSize
    }

    Text {
        id: detailLabel
        anchors.right: parent.right
        anchors.rightMargin: Theme.itemPadding
        anchors.verticalCenter: parent.verticalCenter
        text: root.detail
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pointSize: Theme.dialogSmallPointSize
    }

    Text {
        id: lockLabel
        anchors.right: detailLabel.left
        anchors.rightMargin: Theme.itemPadding
        anchors.verticalCenter: parent.verticalCenter
        visible: root.secured
        text: "󰌾"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pointSize: Theme.dialogSmallPointSize
    }

    Text {
        anchors.left: iconLabel.right
        anchors.leftMargin: Theme.itemPadding
        anchors.right: root.secured ? lockLabel.left : detailLabel.left
        anchors.rightMargin: Theme.itemPadding
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: root.dimmed ? Theme.muted : root.active ? Theme.blue : Theme.text
        font.family: Theme.fontFamily
        font.pointSize: Theme.dialogSmallPointSize
        font.bold: root.active
        font.italic: root.dimmed
        elide: Text.ElideRight
    }
}
