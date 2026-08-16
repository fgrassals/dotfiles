import QtQuick
import qs

Rectangle {
    id: root

    property var device: null
    property string title: ""
    property bool focused: false

    signal picked

    readonly property bool connected: device?.connected ?? false
    readonly property bool paired: (device?.paired ?? false) || (device?.bonded ?? false)
    readonly property bool hasBattery: device?.batteryAvailable ?? false

    implicitHeight: Theme.bluetoothRowHeight
    color: focused ? Theme.surface1 : "transparent"
    border.width: 1
    border.color: focused ? Theme.blue : "transparent"

    MouseArea {
        anchors.fill: parent
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
            text: root.connected ? "󰂱" : root.paired ? "󰂯" : "󰂰"
            color: root.connected ? Theme.blue : Theme.muted
            font.family: Theme.fontFamily
            font.pointSize: Theme.menuFontPointSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 110
            text: root.title
            color: root.connected ? Theme.blue : Theme.text
            font.family: Theme.fontFamily
            font.pointSize: Theme.dialogSmallPointSize
            font.bold: root.connected
            elide: Text.ElideRight
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hasBattery
            text: Math.round((root.device?.battery ?? 0) * 100) + "%"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pointSize: Theme.dialogSmallPointSize
        }
    }
}
