import Quickshell
import Quickshell.Wayland
import QtQuick
import qs

// Scrim and centred card shared by every panel. Wrap in a LazyLoader.
PanelWindow {
    id: root

    property string namespace: ""
    property int cardWidth: Theme.panelWidth
    property color scrim: Theme.scrimLight
    property real offset: 0
    // Set when the panel handles Escape itself, e.g. to close a password field.
    property bool interceptEscape: false

    default property alias content: card.data

    signal closeRequested
    signal keyPressed(var event)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusiveZone: 0
    WlrLayershell.namespace: root.namespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: root.scrim

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.closeRequested();
                event.accepted = true;
                return;
            }
            root.keyPressed(event);
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }

        Rectangle {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.offset
            implicitWidth: root.cardWidth
            implicitHeight: card.implicitHeight + Theme.notifPadding * 2
            clip: true
            color: Theme.notifBg
            border.width: Theme.notifBorderSize
            border.color: Theme.blue

            Column {
                id: card
                anchors.centerIn: parent
                width: parent.width - Theme.notifPadding * 2
                spacing: Theme.notifPadding
            }
        }
    }
}
