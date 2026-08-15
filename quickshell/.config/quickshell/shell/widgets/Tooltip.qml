import Quickshell
import QtQuick
import qs

PopupWindow {
    id: root

    required property Item target
    property string label: ""
    property bool hovered: false

    property bool shown: false

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    implicitWidth: tooltipBody.implicitWidth + Theme.tooltipPadding * 2 + 2
    implicitHeight: tooltipBody.implicitHeight + Theme.tooltipPadding * 2 + 2
    color: "transparent"
    visible: shown && label !== ""

    onHoveredChanged: {
        if (hovered) {
            delay.restart();
        } else {
            delay.stop();
            shown = false;
        }
    }

    Timer {
        id: delay
        interval: Theme.tooltipDelay
        onTriggered: root.shown = true
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.tooltipBg
        border.width: 1
        border.color: Theme.surface1

        Text {
            id: tooltipBody
            anchors.centerIn: parent
            text: root.label
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
