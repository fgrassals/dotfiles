import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs

Rectangle {
    id: root

    required property Notification notification

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical

    implicitWidth: Theme.notifWidth
    implicitHeight: Math.min(Theme.notifMaxHeight, body.implicitHeight + Theme.notifPadding * 2)

    color: Theme.notifBg
    border.width: Theme.notifBorderSize
    border.color: critical ? Theme.peach : Theme.blue

    Timer {
        running: !root.critical
        interval: root.notification.expireTimeout > 0 ? root.notification.expireTimeout * 1000 : Theme.notifTimeout
        onTriggered: root.notification.expire()
    }

    readonly property string iconSource: notification.image || (notification.appIcon ? Quickshell.iconPath(notification.appIcon, true) : "")

    Image {
        id: icon
        visible: root.iconSource !== ""
        anchors.left: parent.left
        anchors.leftMargin: Theme.notifPadding
        anchors.verticalCenter: parent.verticalCenter
        width: visible ? Theme.notifIconSize : 0
        height: width
        source: root.iconSource
        sourceSize.width: Theme.notifIconSize
        sourceSize.height: Theme.notifIconSize
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Column {
        id: body
        anchors.left: icon.visible ? icon.right : parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Theme.notifPadding
        spacing: 4

        Text {
            width: parent.width
            text: root.notification.summary
            color: Theme.text
            font.family: Theme.fontFamily
            font.pointSize: Theme.notifFontPointSize
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: root.notification.body !== ""
            text: root.notification.body
            color: Theme.text
            font.family: Theme.fontFamily
            font.pointSize: Theme.notifFontPointSize
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const fallback = root.notification.actions.find(a => a.identifier === "default");
            if (fallback)
                fallback.invoke();
            else
                root.notification.dismiss();
        }
    }
}
