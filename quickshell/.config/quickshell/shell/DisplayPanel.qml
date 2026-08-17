import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs

Scope {
    id: root

    readonly property bool open: ShellState.openPanel === "display"
    property int selectedIndex: 0
    property var outputs: []

    readonly property int enabledCount: root.outputs.filter(o => !o.disabled).length
    readonly property var selectedOutput: root.outputs[root.selectedIndex] ?? null
    readonly property string enterVerb: root.selectedOutput?.disabled ? "enable" : "disable"

    // HyprlandMonitor is read-only and has no disabled/refreshRate.
    Process {
        id: probe
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.outputs = JSON.parse(this.text);
                } catch (e) {
                    root.outputs = [];
                }
                if (root.selectedIndex >= root.outputs.length)
                    root.selectedIndex = Math.max(0, root.outputs.length - 1);
            }
        }
    }

    function refresh(): void {
        probe.running = true;
    }

    // The Lua parser rejects `hyprctl keyword`; hl.monitor calls are cumulative,
    // so flipping disabled alone keeps the declared mode and scale.
    function toggleSelected(): void {
        const output = root.selectedOutput;
        if (!output)
            return;
        if (!output.disabled && root.enabledCount <= 1)
            return;
        Quickshell.execDetached(["hyprctl", "eval", `hl.monitor({ output = "${output.name}", disabled = ${!output.disabled} })`]);
        settle.restart();
    }

    function reloadRenderer(): void {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.force_renderer_reload()"]);
        settle.restart();
    }

    // Hotplug changes the monitor count; re-read rather than poll.
    readonly property int monitorCount: Hyprland.monitors?.values?.length ?? 0

    onOpenChanged: {
        if (root.open) {
            root.selectedIndex = 0;
            root.refresh();
        }
    }
    onMonitorCountChanged: if (root.open) settle.restart()

    Timer {
        id: settle
        interval: 400
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "display"

        function toggle(): void {
            ShellState.toggle("display");
        }
    }

    LazyLoader {
        active: root.open

        PanelFrame {
            namespace: "quickshell-display"

            onCloseRequested: ShellState.close()

            onKeyPressed: event => {
                const count = root.outputs.length;
                if (event.key === Qt.Key_R) {
                    root.reloadRenderer();
                } else if (count === 0) {
                    return;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    root.selectedIndex = (root.selectedIndex + 1) % count;
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    root.selectedIndex = (root.selectedIndex - 1 + count) % count;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.toggleSelected();
                } else {
                    return;
                }
                event.accepted = true;
            }

            PanelHeader {
                icon: "󰍹"
                title: "Display"
                status: root.outputs.length === 0 ? "" : root.enabledCount + " of " + root.outputs.length + " active"
            }

            SectionHeader {
                width: parent.width
                text: "Outputs"
            }

            Text {
                visible: root.outputs.length === 0
                width: parent.width
                text: "No outputs"
                leftPadding: Theme.itemPadding
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                font.italic: true
            }

            Repeater {
                model: root.outputs

                delegate: PanelRow {
                    required property int index
                    required property var modelData

                    width: parent.width
                    icon: modelData.disabled ? "󰶚" : "󰍹"
                    title: modelData.name
                    detail: modelData.disabled ? "Disabled" : modelData.width + "x" + modelData.height + "  " + modelData.scale + "x"
                    active: !modelData.disabled
                    dimmed: modelData.disabled
                    focused: index === root.selectedIndex
                    onPicked: root.selectedIndex = index
                }
            }

            Text {
                width: parent.width
                text: "↑↓ · ⏎ " + root.enterVerb + " · r reload renderer · Esc"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
