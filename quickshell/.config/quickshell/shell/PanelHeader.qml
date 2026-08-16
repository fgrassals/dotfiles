import QtQuick
import qs

Item {
    id: root

    property string icon: ""
    property string title: ""
    property string status: ""
    property color iconColor: Theme.blue
    property real bottomMargin: Theme.itemPadding

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight + root.bottomMargin

    Row {
        id: row
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: Theme.itemPadding

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.iconColor
            font.family: Theme.fontFamily
            font.pointSize: Theme.menuFontPointSize + 4
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pointSize: Theme.menuFontPointSize
                font.bold: true
            }

            Text {
                visible: root.status !== ""
                text: root.status
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
            }
        }
    }
}
