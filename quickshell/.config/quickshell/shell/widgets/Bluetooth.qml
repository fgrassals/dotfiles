import Quickshell
import Quickshell.Bluetooth
import QtQuick
import qs

Text {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connectedDevices: Bluetooth.devices?.values?.filter(d => d.connected) ?? []
    readonly property bool hasConnection: connectedDevices.length > 0

    verticalAlignment: Text.AlignVCenter
    leftPadding: Theme.itemPadding
    rightPadding: Theme.itemPadding
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    text: !enabled ? "󰂲" : hasConnection ? "󰂱" : "󰂯"

    color: {
        if (mouse.containsMouse) return Theme.blue;
        if (!enabled) return Theme.muted;
        if (hasConnection) return Theme.blue;
        return Theme.text;
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: event => {
            if (event.button === Qt.RightButton) {
                if (root.adapter)
                    root.adapter.enabled = !root.adapter.enabled;
            } else {
                Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "bluetooth", "toggle"]);
            }
        }
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        label: root.hasConnection ? root.connectedDevices.map(d => d.name).join(", ") : "Bluetooth: " + (root.enabled ? "on" : "off")
    }
}
