pragma Singleton

import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property bool idleInhibited: false

    // "" | audio | bluetooth | network | display | powermenu | powertuning | notifications
    property string openPanel: ""

    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0] ?? null

    function toggle(name: string): void {
        root.openPanel = root.openPanel === name ? "" : name;
    }

    function close(): void {
        root.openPanel = "";
    }
}
