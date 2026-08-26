import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs

Scope {
    id: root

    readonly property bool open: ShellState.openPanel === "powermenu"
    property int selectedIndex: 0

    readonly property var entries: [
        { icon: "󰌾", label: "Lock", exec: ["loginctl", "lock-session"] },
        { icon: "󰍃", label: "Logout", exec: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { icon: "󰒲", label: "Suspend", exec: ["systemctl", "suspend"] },
        { icon: "󰜉", label: "Reboot", exec: ["systemctl", "reboot"] },
        { icon: "󰐥", label: "Shutdown", exec: ["systemctl", "poweroff"] }
    ]

    onOpenChanged: if (root.open) root.selectedIndex = 0

    function activate(index: int): void {
        const entry = root.entries[index];
        ShellState.close();
        if (entry)
            Quickshell.execDetached(entry.exec);
    }

    IpcHandler {
        target: "powermenu"

        function toggle(): void {
            ShellState.toggle("powermenu");
        }
    }

    LazyLoader {
        active: root.open

        PanelFrame {
            namespace: "quickshell-powermenu"
            cardWidth: Theme.menuWidth
            scrim: Theme.scrim

            onCloseRequested: ShellState.close()

            onKeyPressed: event => {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    root.selectedIndex = (root.selectedIndex + 1) % root.entries.length;
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    root.selectedIndex = (root.selectedIndex - 1 + root.entries.length) % root.entries.length;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activate(root.selectedIndex);
                } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
                    root.activate(event.key - Qt.Key_1);
                } else {
                    return;
                }
                event.accepted = true;
            }

            PanelHeader {
                icon: "󰐥"
                title: "Power"
            }

            Repeater {
                model: root.entries

                delegate: Rectangle {
                    id: row

                    required property int index
                    required property var modelData

                    width: parent.width
                    implicitHeight: Theme.menuRowHeight
                    color: index === root.selectedIndex ? Theme.surface1 : "transparent"

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: root.selectedIndex = row.index
                        onClicked: root.activate(row.index)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Theme.itemPadding
                        width: Theme.menuIconColumn
                        horizontalAlignment: Text.AlignHCenter
                        text: row.modelData.icon
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize + 6
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Theme.itemPadding + Theme.menuIconColumn + Theme.itemPadding
                        text: row.modelData.label
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.itemPadding * 2
                        text: row.index + 1
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                    }
                }
            }
        }
    }
}
