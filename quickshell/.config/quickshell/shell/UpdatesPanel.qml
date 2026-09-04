import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs

Scope {
    id: root

    readonly property bool open: ShellState.openPanel === "updates"

    property int selectedIndex: 0

    readonly property var rows: [
        { key: "pacman", icon: "󰣇", title: "Pacman", count: UpdatesState.pacmanCount },
        { key: "aur", icon: "󰏖", title: "AUR (paru)", count: UpdatesState.aurCount },
        { key: "mise", icon: "󰜫", title: "mise", count: UpdatesState.miseCount },
        { key: "firmware", icon: "", title: "Firmware", count: UpdatesState.firmwareCount },
    ]

    function moveSelection(delta: int): void {
        const count = root.rows.length;
        root.selectedIndex = (root.selectedIndex + delta + count) % count;
    }

    // Closes first; the panel holds exclusive keyboard focus.
    function activate(): void {
        const row = root.rows[root.selectedIndex];
        ShellState.close();
        Quickshell.execDetached(["kitty", "--class=floating-tui", "-e", "update-run", row.key]);
    }

    // Firmware excluded on purpose — it only ever runs alone.
    function updateAll(): void {
        ShellState.close();
        Quickshell.execDetached(["kitty", "--class=floating-tui", "-e", "update-run", "all"]);
    }

    onOpenChanged: if (root.open) root.selectedIndex = 0

    IpcHandler {
        target: "updates"

        function toggle(): void {
            ShellState.toggle("updates");
        }
    }

    LazyLoader {
        active: root.open

        PanelFrame {
            namespace: "quickshell-updates"

            onCloseRequested: ShellState.close()

            onKeyPressed: event => {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    root.moveSelection(1);
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    root.moveSelection(-1);
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activate();
                } else if (event.key === Qt.Key_A) {
                    root.updateAll();
                } else if (event.key === Qt.Key_R) {
                    UpdatesState.refresh();
                } else {
                    return;
                }
                event.accepted = true;
            }

            PanelHeader {
                icon: "󰇚"
                iconColor: UpdatesState.softwareCount + UpdatesState.firmwareCount > 0 ? Theme.yellow : Theme.muted
                title: "Updates"
                status: UpdatesState.softwareCount + UpdatesState.firmwareCount > 0 ? "" : "Up to date"
            }

            Repeater {
                model: root.rows

                delegate: PanelRow {
                    required property int index
                    required property var modelData

                    width: parent.width
                    icon: modelData.icon
                    title: modelData.title
                    detail: modelData.count > 0 ? modelData.count + " updates" : ""
                    dimmed: modelData.count === 0
                    focused: index === root.selectedIndex
                    onPicked: {
                        root.selectedIndex = index;
                        root.activate();
                    }
                }
            }

            Text {
                width: parent.width
                text: "↑↓ · ⏎ update · a all · r refresh · Esc"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
