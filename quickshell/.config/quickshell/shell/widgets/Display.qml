import Quickshell.Hyprland
import QtQuick
import qs

Text {
    id: root

    // Enabled outputs only — DisplayPanel lists the disabled ones too.
    readonly property var monitors: Hyprland.monitors?.values ?? []
    readonly property bool extended: monitors.length > 1

    verticalAlignment: Text.AlignVCenter
    leftPadding: Theme.itemPadding
    rightPadding: Theme.itemPadding
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    text: extended ? "󰍺" : "󰍹"
    color: mouse.containsMouse ? Theme.blue : extended ? Theme.blue : Theme.text

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.toggle("display")
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        label: root.monitors.map(m => m.name + "  " + m.width + "x" + m.height + (m.scale !== 1 ? "  " + m.scale + "x" : "")).join("\n")
    }
}
