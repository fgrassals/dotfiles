import QtQuick
import qs

Rectangle {
    id: root

    property var node: null
    property string title: ""
    property string kind: "sink"
    property bool isDefault: false
    property bool focused: false

    readonly property bool capture: kind === "source" || kind === "instream"

    signal picked

    readonly property real volume: node?.audio?.volume ?? 0
    readonly property bool muted: node?.audio?.muted ?? false

    implicitHeight: Theme.audioRowHeight
    color: focused ? Theme.surface1 : "transparent"
    border.width: 1
    border.color: focused ? Theme.blue : "transparent"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.itemPadding
        anchors.rightMargin: Theme.itemPadding
        spacing: 4

        Row {
            width: parent.width
            spacing: Theme.itemPadding

            Text {
                text: root.capture ? (root.muted ? "󰍭" : "󰍬") : (root.muted ? "󰝟" : "󰕾")
                color: root.muted ? Theme.muted : root.isDefault ? Theme.blue : Theme.text
                font.family: Theme.fontFamily
                font.pointSize: Theme.menuFontPointSize
            }

            Text {
                width: parent.width - 90
                text: root.title
                color: root.isDefault ? Theme.blue : Theme.text
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                font.bold: root.isDefault
                elide: Text.ElideRight
            }

            Text {
                text: Math.round(root.volume * 100) + "%"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
            }
        }

        Rectangle {
            width: parent.width
            height: Theme.osdBarHeight
            color: Theme.bg

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * root.volume
                color: root.muted ? Theme.muted : Theme.blue
            }
        }
    }
}
