import Quickshell
import Quickshell.Io
import QtQuick
import qs

Text {
    id: root

    readonly property bool active: /on/.test(state.text())

    // Written by the `nightlight` script, so SUPER+N and the click both land here.
    FileView {
        id: state
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/nightlight.state"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    Process {
        id: reconcile
        command: ["nightlight", "status"]
        onExited: state.reload()
    }

    // Catches wlsunset exiting on its own.
    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: reconcile.running = true
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
        onClicked: Quickshell.execDetached(["nightlight", "toggle"])
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        label: root.active ? "Night light on" : "Night light off"
    }
}
