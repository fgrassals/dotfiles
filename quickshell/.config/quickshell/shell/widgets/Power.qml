import Quickshell
import QtQuick
import qs

Text {
    id: root

    verticalAlignment: Text.AlignVCenter
    leftPadding: Theme.itemPadding
    rightPadding: Theme.itemPadding
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    text: "󰐥"
    color: mouse.containsMouse ? Theme.red : Theme.muted

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "powermenu", "toggle"])
    }
}
