pragma Singleton

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import qs

Singleton {
    id: root

    // popupIds is the subset of tracked notifications still on screen.
    property var popupIds: []
    property var arrivals: ({})

    // Newest first.
    readonly property var history: {
        const list = (server.trackedNotifications?.values ?? []).slice();
        list.reverse();
        return list;
    }

    readonly property var visibleNotifications: root.history.filter(n => root.popupIds.indexOf(n.id) !== -1).slice(0, Theme.notifMaxVisible)

    // Anything that arrived since the history panel was last opened.
    property real lastSeen: 0
    readonly property int unreadCount: root.history.filter(n => root.arrivedAt(n.id) > root.lastSeen).length
    readonly property bool unreadCritical: root.history.some(n => root.arrivedAt(n.id) > root.lastSeen && n.urgency === NotificationUrgency.Critical)

    function markSeen(): void {
        root.lastSeen = Date.now();
    }

    function arrivedAt(id: int): real {
        return root.arrivals[id] ?? 0;
    }

    function hidePopup(id: int): void {
        root.popupIds = root.popupIds.filter(i => i !== id);
    }

    function drop(notification): void {
        if (!notification)
            return;
        const id = notification.id;
        notification.dismiss();
        root.hidePopup(id);
        const arrivals = root.arrivals;
        delete arrivals[id];
        root.arrivals = arrivals;
    }

    function clearHistory(): void {
        for (const n of root.history.slice())
            n.dismiss();
        root.popupIds = [];
        root.arrivals = ({});
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true;

            const arrivals = root.arrivals;
            arrivals[notification.id] = Date.now();
            root.arrivals = arrivals;

            root.popupIds = [notification.id].concat(root.popupIds.filter(i => i !== notification.id));

            // trackedNotifications is oldest-first.
            const tracked = server.trackedNotifications.values;
            for (let i = 0; i < tracked.length - Theme.notifHistoryMax; i++)
                root.drop(tracked[i]);
        }
    }

    PanelWindow {
        screen: ShellState.focusedScreen
        visible: root.visibleNotifications.length > 0

        anchors {
            top: true
            right: true
        }

        margins.top: Theme.notifMargin
        margins.right: Theme.notifMargin

        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay

        color: "transparent"
        implicitWidth: Theme.notifWidth
        implicitHeight: stack.implicitHeight

        Column {
            id: stack
            anchors.fill: parent
            spacing: Theme.notifMargin

            Repeater {
                model: ScriptModel {
                    values: root.visibleNotifications
                }

                delegate: NotificationCard {
                    required property Notification modelData
                    notification: modelData
                }
            }
        }
    }
}
