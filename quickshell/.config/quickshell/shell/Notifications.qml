import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick
import qs

Scope {
    id: root

    readonly property var visibleNotifications: server.trackedNotifications.values.slice(0, Theme.notifMaxVisible)
    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0] ?? null

    NotificationServer {
        id: server

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notification => notification.tracked = true
    }

    PanelWindow {
        screen: root.focusedScreen
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
