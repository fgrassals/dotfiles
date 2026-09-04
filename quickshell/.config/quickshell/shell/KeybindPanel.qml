import Quickshell
import Quickshell.Io
import QtQuick
import qs

// Renders whatever hyprland.lua binds carry a `desc`/`description` option, read
// live from `hyprctl binds -j` — one source of truth, no separate list to drift.
Scope {
    id: root

    readonly property bool open: ShellState.openPanel === "keybinds"
    property var binds: []

    readonly property var described: root.binds.filter(b => (b.description ?? "") !== "")

    readonly property var categories: {
        const order = [];
        const map = {};
        for (const b of root.described) {
            const cat = root.categoryOf(b.description);
            if (!map[cat]) {
                map[cat] = [];
                order.push(cat);
            }
            map[cat].push(b);
        }
        return order.map(name => ({ name, items: map[name] }));
    }

    readonly property var keyLabels: ({
        left: "←", right: "→", up: "↑", down: "↓",
        Return: "Enter", Escape: "Esc", Space: "Space",
        comma: ",", period: ".", SLASH: "/",
        "mouse:272": "LMB drag", "mouse:273": "RMB drag", mouse_down: "Scroll",
        Print: "PrtSc",
        XF86AudioRaiseVolume: "Vol +", XF86AudioLowerVolume: "Vol −",
        XF86AudioMute: "Mute", XF86AudioMicMute: "Mic mute",
        XF86MonBrightnessUp: "Bright +", XF86MonBrightnessDown: "Bright −",
        XF86AudioNext: "Next", XF86AudioPrev: "Prev",
        XF86AudioPlay: "Play", XF86AudioPause: "Pause",
        "switch:on:Lid Switch": "Lid close", "switch:off:Lid Switch": "Lid open",
    })

    function categoryOf(desc: string): string {
        return desc.split(":")[0];
    }

    function labelOf(desc: string): string {
        return desc.slice(desc.indexOf(":") + 1).trim();
    }

    function modParts(modmask: int): var {
        const parts = [];
        if (modmask & 64) parts.push("Super");
        if (modmask & 4) parts.push("Ctrl");
        if (modmask & 8) parts.push("Alt");
        if (modmask & 1) parts.push("Shift");
        return parts;
    }

    function comboText(bind): string {
        const key = root.keyLabels[bind.key] ?? bind.key;
        return root.modParts(bind.modmask).concat([key]).join(" + ");
    }

    function refresh(): void {
        probe.running = true;
    }

    Process {
        id: probe
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.binds = JSON.parse(this.text);
                } catch (e) {
                    root.binds = [];
                }
            }
        }
    }

    onOpenChanged: if (root.open) root.refresh()

    IpcHandler {
        target: "keybinds"

        function toggle(): void {
            ShellState.toggle("keybinds");
        }
    }

    LazyLoader {
        active: root.open

        PanelFrame {
            namespace: "quickshell-keybinds"
            cardWidth: Theme.keybindPanelWidth

            onCloseRequested: ShellState.close()

            PanelHeader {
                icon: "󰥻"
                title: "Keybinds"
                status: root.described.length + " shortcuts"
            }

            Flickable {
                width: parent.width
                height: Theme.keybindPanelHeight
                contentWidth: width
                contentHeight: list.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: list
                    width: parent.width
                    spacing: Theme.itemPadding

                    Repeater {
                        model: root.categories

                        delegate: Column {
                            required property var modelData

                            width: list.width
                            spacing: 0

                            SectionHeader {
                                width: parent.width
                                text: modelData.name
                            }

                            Repeater {
                                model: modelData.items

                                delegate: PanelRow {
                                    required property var modelData

                                    width: list.width
                                    title: root.labelOf(modelData.description)
                                    detail: root.comboText(modelData)
                                }
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: "Esc"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
