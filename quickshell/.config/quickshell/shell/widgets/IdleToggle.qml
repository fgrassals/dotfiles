import QtQuick
import qs

Text {
    id: root

    verticalAlignment: Text.AlignVCenter
    leftPadding: Theme.itemPadding
    rightPadding: Theme.itemPadding
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    text: ShellState.idleInhibited ? "󰒳" : "󰒲"

    color: {
        if (mouse.containsMouse) return Theme.blue;
        return ShellState.idleInhibited ? Theme.yellow : Theme.muted;
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.idleInhibited = !ShellState.idleInhibited
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        label: ShellState.idleInhibited ? "Idle inhibitor on — screen will not sleep" : "Idle inhibitor off"
    }
}
