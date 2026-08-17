import Quickshell.Services.UPower
import QtQuick
import qs

Text {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property real percent: (battery?.percentage ?? 0) * 100
    readonly property int state: battery?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge

    // 10 discharge steps, U+F007A..U+F0082 then U+F0079 at full
    readonly property var dischargeIcons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    readonly property string timeTo: {
        const secs = charging ? battery?.timeToFull ?? 0 : battery?.timeToEmpty ?? 0;
        if (secs <= 0)
            return "";
        const hours = Math.floor(secs / 3600);
        const minutes = Math.floor((secs % 3600) / 60);
        return (hours > 0 ? hours + " h " : "") + minutes + " min " + (charging ? "to full" : "to empty");
    }

    verticalAlignment: Text.AlignVCenter
    leftPadding: Theme.itemPadding
    rightPadding: Theme.itemPadding
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    text: {
        if (charging)
            return "󰂄 " + Math.round(percent) + "%";
        if (state === UPowerDeviceState.FullyCharged)
            return "󰁹";
        const step = Math.min(9, Math.max(0, Math.floor(percent / 10)));
        return dischargeIcons[step];
    }

    color: {
        if (!charging && percent <= 15) return Theme.red;
        if (!charging && percent <= 30) return Theme.yellow;
        if (mouse.containsMouse) return Theme.blue;
        if (charging || state === UPowerDeviceState.FullyCharged) return Theme.green;
        return Theme.text;
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.toggle("powertuning")
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        label: Math.round(root.percent) + "%" + (root.timeTo ? "  —  " + root.timeTo : "") + "\n" + Math.abs(root.battery?.changeRate ?? 0).toFixed(1) + "W"
    }
}
