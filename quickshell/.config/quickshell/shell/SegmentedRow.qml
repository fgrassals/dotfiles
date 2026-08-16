import QtQuick
import qs

Column {
    id: root

    property string title: ""
    property var entries: []
    property int selected: 0
    property bool focused: false

    signal picked(int index)

    spacing: 6

    Text {
        text: root.title
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pointSize: Theme.dialogSmallPointSize
    }

    Row {
        id: cells

        readonly property real cellWidth: root.entries.length > 0 ? (root.width - spacing * (root.entries.length - 1)) / root.entries.length : 0

        width: root.width
        spacing: 6

        Repeater {
            model: root.entries

            delegate: Rectangle {
                id: cell

                required property int index
                required property var modelData

                readonly property bool active: index === root.selected

                width: cells.cellWidth
                height: Theme.segmentHeight
                color: active ? Theme.surface1 : "transparent"
                border.width: 1
                border.color: active && root.focused ? Theme.blue : Theme.surface1

                Column {
                    anchors.centerIn: parent
                    spacing: 1

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: cell.modelData.icon
                        color: cell.active ? Theme.text : Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize + 4
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: cell.modelData.label
                        color: cell.active ? Theme.text : Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.dialogSmallPointSize
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(cell.index)
                }
            }
        }
    }
}
