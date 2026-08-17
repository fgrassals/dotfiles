import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import QtQuick
import qs

Scope {
    id: root

    property bool open: false

    // Anchored to the device, not the index: discovery adds and drops rows.
    property var selectedDevice: null
    readonly property int selectedIndex: {
        const i = root.rows.findIndex(r => r.device === root.selectedDevice);
        return i >= 0 ? i : 0;
    }
    readonly property var currentDevice: root.rows[root.selectedIndex]?.device ?? null
    // Set only when this panel started the scan; never stops another client's.
    property bool startedDiscovery: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var devices: Bluetooth.devices?.values ?? []

    readonly property var known: devices.filter(d => root.isKnown(d))
    readonly property var discovered: devices.filter(d => !root.isKnown(d))

    readonly property string enterVerb: {
        const device = root.currentDevice;
        if (device?.connected)
            return "disconnect";
        return root.isKnown(device) ? "connect" : "pair";
    }

    readonly property var rows: {
        const list = [];
        for (const d of root.known)
            list.push({ device: d, section: "Paired" });
        for (const d of root.discovered)
            list.push({ device: d, section: "Available" });
        return list;
    }

    function isKnown(device): bool {
        return (device?.paired ?? false) || (device?.bonded ?? false) || (device?.trusted ?? false);
    }

    function moveSelection(delta: int): void {
        const count = root.rows.length;
        if (count === 0)
            return;
        root.selectedDevice = root.rows[(root.selectedIndex + delta + count) % count]?.device ?? null;
    }

    function deviceIcon(device): string {
        if (device?.connected)
            return "󰂱";
        return root.isKnown(device) ? "󰂯" : "󰂰";
    }

    function batteryLabel(device): string {
        return (device?.batteryAvailable ?? false) ? Math.round((device?.battery ?? 0) * 100) + "%" : "";
    }

    function label(device): string {
        return device?.name || device?.deviceName || device?.address || "";
    }

    function activate(): void {
        const device = root.currentDevice;
        if (!device)
            return;
        if (root.isKnown(device))
            device.connected = !device.connected;
        else
            device.pair();
    }

    function forget(): void {
        const device = root.currentDevice;
        if (root.isKnown(device))
            device.forget();
    }

    function togglePower(): void {
        if (root.adapter)
            root.adapter.enabled = !root.adapter.enabled;
    }

    function show(): void {
        root.selectedDevice = null;
        root.open = true;
    }

    onOpenChanged: discoverySettle.restart()

    // BlueZ rejects overlapping StartDiscovery/StopDiscovery.
    Timer {
        id: discoverySettle
        interval: 300
        onTriggered: {
            if (!root.adapter)
                return;
            if (root.open) {
                if (root.enabled && !root.adapter.discovering) {
                    root.adapter.discovering = true;
                    root.startedDiscovery = true;
                }
            } else if (root.startedDiscovery && root.adapter.discovering) {
                root.adapter.discovering = false;
                root.startedDiscovery = false;
            }
        }
    }

    IpcHandler {
        target: "bluetooth"

        function toggle(): void {
            if (root.open)
                root.open = false;
            else
                root.show();
        }
    }

    LazyLoader {
        active: root.open

        PanelFrame {
            namespace: "quickshell-bluetooth"

            onCloseRequested: root.open = false

            onKeyPressed: event => {
                const count = root.rows.length;
                if (event.key === Qt.Key_P) {
                    root.togglePower();
                } else if (count === 0) {
                    return;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    root.moveSelection(1);
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    root.moveSelection(-1);
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activate();
                } else if (event.key === Qt.Key_F) {
                    root.forget();
                } else {
                    return;
                }
                event.accepted = true;
            }

            PanelHeader {
                icon: root.enabled ? "󰂯" : "󰂲"
                iconColor: root.enabled ? Theme.blue : Theme.muted
                title: "Bluetooth"
                status: !root.enabled ? "Off" : root.adapter?.discovering ? "Scanning…" : "On"
            }

            SectionHeader {
                width: parent.width
                text: "Paired"
            }

            Text {
                visible: root.known.length === 0
                width: parent.width
                text: "No paired devices"
                leftPadding: Theme.itemPadding
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                font.italic: true
            }

            Repeater {
                model: root.known

                delegate: PanelRow {
                    required property int index
                    required property var modelData

                    width: parent.width
                    icon: root.deviceIcon(modelData)
                    title: root.label(modelData)
                    detail: root.batteryLabel(modelData)
                    active: modelData.connected
                    focused: index === root.selectedIndex
                    onPicked: root.selectedDevice = modelData
                }
            }

            SectionHeader {
                width: parent.width
                text: "Available"
            }

            Text {
                visible: root.discovered.length === 0
                width: parent.width
                text: root.adapter?.discovering ? "Scanning…" : "Nothing found"
                leftPadding: Theme.itemPadding
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                font.italic: true
            }

            Repeater {
                model: root.discovered

                delegate: PanelRow {
                    required property int index
                    required property var modelData

                    width: parent.width
                    icon: root.deviceIcon(modelData)
                    title: root.label(modelData)
                    detail: root.batteryLabel(modelData)
                    active: modelData.connected
                    focused: (root.known.length + index) === root.selectedIndex
                    onPicked: root.selectedDevice = modelData
                }
            }

            Text {
                width: parent.width
                text: "↑↓ · ⏎ " + root.enterVerb + " · f forget · p power · Esc"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
