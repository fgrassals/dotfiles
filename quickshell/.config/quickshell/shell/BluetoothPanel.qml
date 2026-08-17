import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import QtQuick
import qs

Scope {
    id: root

    property bool open: false
    property int selectedIndex: 0
    // Set only when this panel started the scan, so closing never stops a
    // discovery session another client owns.
    property bool startedDiscovery: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var devices: Bluetooth.devices?.values ?? []

    readonly property var known: devices.filter(d => d.paired || d.bonded || d.trusted)
    readonly property var discovered: devices.filter(d => !(d.paired || d.bonded || d.trusted))

    readonly property string enterVerb: {
        const device = root.rows[root.selectedIndex]?.device;
        if (device?.connected)
            return "disconnect";
        if (device?.paired || device?.bonded || device?.trusted)
            return "connect";
        return "pair";
    }

    readonly property var rows: {
        const list = [];
        for (const d of root.known)
            list.push({ device: d, section: "Paired" });
        for (const d of root.discovered)
            list.push({ device: d, section: "Available" });
        return list;
    }

    function label(device): string {
        return device?.name || device?.deviceName || device?.address || "";
    }

    function activate(): void {
        const device = root.rows[root.selectedIndex]?.device;
        if (!device)
            return;
        if (device.paired || device.bonded || device.trusted)
            device.connected = !device.connected;
        else
            device.pair();
    }

    function forget(): void {
        const device = root.rows[root.selectedIndex]?.device;
        if (device?.paired || device?.bonded || device?.trusted)
            device.forget();
    }

    function togglePower(): void {
        if (root.adapter)
            root.adapter.enabled = !root.adapter.enabled;
    }

    function show(): void {
        root.selectedIndex = 0;
        root.open = true;
    }

    onOpenChanged: discoverySettle.restart()

    // BlueZ rejects overlapping StartDiscovery/StopDiscovery calls, so rapid
    // open/close is coalesced into one request.
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

        PanelWindow {
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell-bluetooth"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Theme.scrimLight

            Item {
                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    const count = root.rows.length;
                    if (event.key === Qt.Key_Escape) {
                        root.open = false;
                    } else if (event.key === Qt.Key_P) {
                        root.togglePower();
                    } else if (count === 0) {
                        return;
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        root.selectedIndex = (root.selectedIndex + 1) % count;
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        root.selectedIndex = (root.selectedIndex - 1 + count) % count;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.activate();
                    } else if (event.key === Qt.Key_F) {
                        root.forget();
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                }

                Rectangle {
                    anchors.centerIn: parent
                    implicitWidth: Theme.audioWidth
                    implicitHeight: layout.implicitHeight + Theme.notifPadding * 2
                    color: Theme.notifBg
                    border.width: Theme.notifBorderSize
                    border.color: Theme.blue

                    Column {
                        id: layout
                        anchors.centerIn: parent
                        width: parent.width - Theme.notifPadding * 2
                        spacing: Theme.notifPadding

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

                            delegate: BluetoothRow {
                                required property int index
                                required property var modelData

                                width: layout.width
                                device: modelData
                                title: root.label(modelData)
                                focused: index === root.selectedIndex
                                onPicked: root.selectedIndex = index
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

                            delegate: BluetoothRow {
                                required property int index
                                required property var modelData

                                width: layout.width
                                device: modelData
                                title: root.label(modelData)
                                focused: (root.known.length + index) === root.selectedIndex
                                onPicked: root.selectedIndex = root.known.length + index
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
        }
    }
}
