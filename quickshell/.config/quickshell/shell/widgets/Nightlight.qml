import Quickshell
import Quickshell.Io
import QtQuick
import qs

Text {
    id: root

    property bool active: false

    Process {
        id: probe
        command: ["pgrep", "-x", "wlsunset"]
        onExited: code => root.active = code === 0
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: probe.running = true
    }

    Timer {
        id: afterToggle
        interval: 400
        onTriggered: probe.running = true
    }

    verticalAlignment: Text.AlignVCenter
    leftPadding: Theme.itemPadding
    rightPadding: Theme.itemPadding
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    text: active ? "󰖔" : "󰖕"
    color: mouse.containsMouse ? Theme.blue : active ? Theme.yellow : Theme.muted

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["nightlight", "toggle"]);
            afterToggle.restart();
        }
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        label: root.active ? "Night light on" : "Night light off"
    }
}
