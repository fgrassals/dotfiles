import Quickshell
import Quickshell.Io
import QtQuick
import qs

Text {
    id: root

    readonly property bool dark: /gtk-application-prefer-dark-theme\s*=\s*1/.test(settings.text())

    // gtk-theme-mode writes this file; watching it replaces waybar's RTMIN signal.
    FileView {
        id: settings
        path: Quickshell.env("HOME") + "/.config/gtk-3.0/settings.ini"
        watchChanges: true
        onFileChanged: reload()
    }

    verticalAlignment: Text.AlignVCenter
    leftPadding: Theme.itemPadding
    rightPadding: Theme.itemPadding
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    text: dark ? "󰽥" : "󰖨"
    color: mouse.containsMouse ? Theme.blue : dark ? Theme.blue : Theme.yellow

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["gtk-theme-mode", "toggle"])
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        label: root.dark ? "GTK theme: dark" : "GTK theme: light"
    }
}
