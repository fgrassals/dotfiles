import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root

    property real cpuUsage: 0
    property var previousCpu: null

    implicitWidth: row.implicitWidth + Theme.groupPadding * 2
    implicitHeight: Theme.barHeight
    color: Theme.pill

    component StatItem: Text {
        id: item

        property color stateColor: Theme.text
        property bool clickable: false
        property string tooltipLabel: ""
        signal activated

        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        leftPadding: Theme.itemPadding
        rightPadding: Theme.itemPadding
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: itemMouse.containsMouse ? Theme.blue : item.stateColor

        MouseArea {
            id: itemMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: item.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: item.activated()
        }

        Tooltip {
            target: item
            hovered: itemMouse.containsMouse
            label: item.tooltipLabel
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            tempFile.reload();
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            const fields = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            if (fields.length < 5)
                return;

            const idle = fields[3] + fields[4];
            const total = fields.reduce((a, b) => a + b, 0);

            if (root.previousCpu) {
                const dTotal = total - root.previousCpu.total;
                const dIdle = idle - root.previousCpu.idle;
                if (dTotal > 0)
                    root.cpuUsage = Math.max(0, Math.min(100, (1 - dIdle / dTotal) * 100));
            }
            root.previousCpu = { idle: idle, total: total };
        }
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
    }

    FileView {
        id: tempFile
        path: "/sys/class/thermal/thermal_zone0/temp"
    }

    readonly property int memTotalKb: Number(/MemTotal:\s+(\d+)/.exec(memFile.text())?.[1] ?? 0)
    readonly property int memAvailableKb: Number(/MemAvailable:\s+(\d+)/.exec(memFile.text())?.[1] ?? 0)
    readonly property int memUsedKb: memTotalKb - memAvailableKb
    readonly property real memUsedGb: memUsedKb / 1024 / 1024
    readonly property real memPercent: memTotalKb > 0 ? (memUsedKb / memTotalKb) * 100 : 0
    readonly property real tempC: Number(tempFile.text()) / 1000

    RowLayout {
        id: row
        anchors.centerIn: parent
        height: parent.height
        spacing: 0

        StatItem {
            text: "󰍛 " + Math.round(root.cpuUsage) + "%"
            stateColor: root.cpuUsage >= 90 ? Theme.red : root.cpuUsage >= 70 ? Theme.yellow : Theme.text
            tooltipLabel: "CPU " + Math.round(root.cpuUsage) + "%"
            clickable: true
            onActivated: Quickshell.execDetached(["kitty", "--class=floating-btop", "-e", "btop"])
        }

        StatItem {
            text: "󰘚 " + root.memUsedGb.toFixed(1) + "G"
            stateColor: root.memPercent >= 90 ? Theme.red : root.memPercent >= 80 ? Theme.yellow : Theme.text
            tooltipLabel: root.memUsedGb.toFixed(1) + "GiB used of " + (root.memTotalKb / 1024 / 1024).toFixed(1) + "GiB"
            clickable: true
            onActivated: Quickshell.execDetached(["kitty", "--class=floating-btop", "-e", "btop"])
        }

        StatItem {
            text: "󰔏 " + Math.round(root.tempC) + "°C"
            stateColor: root.tempC >= 80 ? Theme.red : Theme.text
            tooltipLabel: Math.round(root.tempC) + "°C"
        }
    }
}
