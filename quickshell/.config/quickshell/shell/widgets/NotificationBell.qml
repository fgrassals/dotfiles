import QtQuick
import qs

Rectangle {
    id: root

    readonly property int total: NotificationStore.history.length
    readonly property int unread: NotificationStore.unreadCount

    implicitWidth: label.implicitWidth + Theme.clockPadding * 2
    implicitHeight: Theme.barHeight
    color: Theme.pill

    Text {
        id: label
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize

        text: {
            if (root.unread > 0)
                return "󰂚 " + root.unread;
            return root.total > 0 ? "󰂚" : "󰂛";
        }

        color: {
            if (mouse.containsMouse) return Theme.blue;
            if (NotificationStore.unreadCritical) return Theme.red;
            if (root.unread > 0) return Theme.peach;
            return root.total > 0 ? Theme.text : Theme.muted;
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: event => {
            if (event.button === Qt.RightButton)
                NotificationStore.clearHistory();
            else
                ShellState.toggle("notifications");
        }
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        label: {
            if (root.total === 0)
                return "No notifications";
            const kept = root.total + (root.total === 1 ? " notification" : " notifications");
            return root.unread > 0 ? root.unread + " unread  —  " + kept : kept;
        }
    }
}
