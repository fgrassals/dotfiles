import QtQuick
import qs

Rectangle {
    id: root

    readonly property int softwareCount: UpdatesState.softwareCount
    readonly property int firmwareCount: UpdatesState.firmwareCount
    readonly property int total: softwareCount + firmwareCount

    visible: total > 0
    implicitWidth: label.implicitWidth + Theme.clockPadding * 2
    implicitHeight: Theme.barHeight
    color: Theme.pill

    Text {
        id: label
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize

        text: "󰇚 " + root.total

        color: {
            if (mouse.containsMouse) return Theme.blue;
            if (root.firmwareCount > 0) return Theme.red;
            if (root.softwareCount >= 10) return Theme.yellow;
            return Theme.text;
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.toggle("updates")
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        label: {
            const parts = [];
            if (UpdatesState.pacmanCount > 0) parts.push(UpdatesState.pacmanCount + " pacman");
            if (UpdatesState.aurCount > 0) parts.push(UpdatesState.aurCount + " AUR");
            if (UpdatesState.miseCount > 0) parts.push(UpdatesState.miseCount + " mise");
            if (UpdatesState.firmwareCount > 0) parts.push(UpdatesState.firmwareCount + " firmware");
            return parts.length > 0 ? parts.join("\n") : "No updates";
        }
    }
}
