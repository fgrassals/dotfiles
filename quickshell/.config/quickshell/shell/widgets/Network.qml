import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import qs

Text {
    id: root

    readonly property var devices: Networking.devices?.values ?? []
    readonly property bool wiredUp: devices.some(d => d.connected && d.type === DeviceType.Wired)
    readonly property bool wifiUp: devices.some(d => d.connected && d.type === DeviceType.Wifi)
    readonly property bool disconnected: !wiredUp && !wifiUp && Networking.wifiEnabled

    readonly property var activeDevice: devices.find(d => d.connected && (d.type === DeviceType.Wired || d.type === DeviceType.Wifi)) ?? null
    readonly property var activeNetwork: activeDevice?.networks?.values?.find(n => n.connected) ?? null

    property string ipAddress: ""

    Process {
        id: ipProbe
        command: ["ip", "-4", "-o", "addr", "show", "dev", root.activeDevice?.name ?? "lo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = /inet (\d+\.\d+\.\d+\.\d+)/.exec(this.text);
                root.ipAddress = match ? match[1] : "";
            }
        }
    }

    verticalAlignment: Text.AlignVCenter
    leftPadding: Theme.itemPadding
    rightPadding: Theme.itemPadding
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    text: {
        if (wiredUp)
            return "󱘖";
        if (wifiUp)
            return "󰤨";
        if (!Networking.wifiEnabled)
            return "󰤮";
        return "󰤭";
    }

    color: mouse.containsMouse ? Theme.blue : disconnected ? Theme.red : Theme.text

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (root.activeDevice) ipProbe.running = true
        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        label: {
            if (root.wiredUp)
                return (root.activeDevice?.name ?? "") + "  " + root.ipAddress;
            if (root.wifiUp) {
                const signal = Math.round((root.activeNetwork?.signalStrength ?? 0) * 100);
                return (root.activeNetwork?.name ?? "") + "  " + signal + "%\n" + root.ipAddress;
            }
            if (!Networking.wifiEnabled)
                return "Wi-Fi off";
            return "Disconnected";
        }
    }
}
