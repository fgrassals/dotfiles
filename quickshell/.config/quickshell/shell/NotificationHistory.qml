import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import qs

Scope {
    id: root

    readonly property bool open: ShellState.openPanel === "notifications"

    // Anchored to the notification, not the index: entries arrive and get dropped.
    property var selected: null
    readonly property var rows: NotificationStore.history
    readonly property int selectedIndex: {
        const i = root.rows.findIndex(n => n === root.selected);
        return i >= 0 ? i : 0;
    }
    readonly property var currentNotification: root.rows[root.selectedIndex] ?? null

    // Ticks the relative times while the panel is open.
    SystemClock {
        id: clock
        enabled: root.open
        precision: SystemClock.Minutes
    }

    function ago(id: int): string {
        const at = NotificationStore.arrivedAt(id);
        if (at === 0)
            return "";
        const minutes = Math.floor((clock.date.getTime() - at) / 60000);
        if (minutes < 1)
            return "now";
        if (minutes < 60)
            return minutes + "m";
        const hours = Math.floor(minutes / 60);
        if (hours < 24)
            return hours + "h";
        return Math.floor(hours / 24) + "d";
    }

    function moveSelection(delta: int): void {
        const count = root.rows.length;
        if (count === 0)
            return;
        root.selected = root.rows[(root.selectedIndex + delta + count) % count] ?? null;
    }

    function activate(): void {
        const notification = root.currentNotification;
        if (!notification)
            return;
        const fallback = notification.actions.find(a => a.identifier === "default");
        if (fallback)
            fallback.invoke();
        NotificationStore.drop(notification);
    }

    function dropSelected(): void {
        NotificationStore.drop(root.currentNotification);
    }

    onOpenChanged: {
        if (!root.open)
            return;
        root.selected = null;
        NotificationStore.markSeen();
    }

    // Arrivals while the panel is on screen have already been seen.
    onRowsChanged: if (root.open) NotificationStore.markSeen()

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            ShellState.toggle("notifications");
        }
    }

    LazyLoader {
        active: root.open

        PanelFrame {
            namespace: "quickshell-notifications"

            onCloseRequested: ShellState.close()

            onKeyPressed: event => {
                if (event.key === Qt.Key_C) {
                    NotificationStore.clearHistory();
                } else if (root.rows.length === 0) {
                    return;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    root.moveSelection(1);
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    root.moveSelection(-1);
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activate();
                } else if (event.key === Qt.Key_X || event.key === Qt.Key_Delete) {
                    root.dropSelected();
                } else {
                    return;
                }
                event.accepted = true;
            }

            PanelHeader {
                icon: root.rows.length > 0 ? "󰂚" : "󰂛"
                iconColor: root.rows.length > 0 ? Theme.blue : Theme.muted
                title: "Notifications"
                status: root.rows.length === 0 ? "" : root.rows.length + (root.rows.length === 1 ? " notification" : " notifications")
            }

            SectionHeader {
                width: parent.width
                text: "Recent"
            }

            Text {
                visible: root.rows.length === 0
                width: parent.width
                text: "Nothing to show"
                leftPadding: Theme.itemPadding
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                font.italic: true
            }

            // The 1px overhang keeps the clip boundary off the focused row's border.
            Flickable {
                id: scroller

                x: -1
                width: parent.width + 2
                visible: root.rows.length > 0
                // Half a row peeks on overflow.
                implicitHeight: (root.rows.length > Theme.historyMaxRows ? Theme.historyMaxRows + 0.5 : root.rows.length) * Theme.rowHeight
                contentWidth: width
                contentHeight: list.implicitHeight
                clip: true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                function revealSelection(): void {
                    const top = root.selectedIndex * Theme.rowHeight;
                    const bottom = top + Theme.rowHeight;
                    if (top < scroller.contentY)
                        scroller.contentY = top;
                    else if (bottom > scroller.contentY + scroller.height)
                        scroller.contentY = bottom - scroller.height;
                }

                Connections {
                    target: root
                    function onSelectedIndexChanged() {
                        scroller.revealSelection();
                    }
                }

                Column {
                    id: list
                    x: 1
                    width: scroller.width - 2

                    Repeater {
                        model: ScriptModel {
                            values: root.rows
                        }

                        delegate: PanelRow {
                            required property var modelData

                            width: parent.width
                            icon: modelData.urgency === NotificationUrgency.Critical ? "󰀪" : "󰂚"
                            title: modelData.summary
                            detail: root.ago(modelData.id)
                            active: modelData.urgency === NotificationUrgency.Critical
                            focused: modelData === root.currentNotification
                            onPicked: root.selected = modelData
                        }
                    }
                }

                Behavior on contentY {
                    NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                }
            }

            Text {
                width: parent.width
                text: "↑↓ · ⏎ open · x dismiss · c clear all · Esc"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
