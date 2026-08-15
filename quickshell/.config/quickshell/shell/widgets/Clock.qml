import Quickshell
import QtQuick
import qs

Rectangle {
    id: root

    property bool showDate: false

    implicitWidth: label.implicitWidth + Theme.clockPadding * 2
    implicitHeight: Theme.barHeight
    color: Theme.pill

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: "󰅐 " + Qt.formatDateTime(clock.date, root.showDate ? "ddd dd MMM" : "HH:mm")
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.showDate = !root.showDate
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        label: Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
    }
}
