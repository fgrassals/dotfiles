import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick
import qs

Scope {
    id: root

    property bool open: false
    property int groupIndex: 0
    property int profileIndex: 0
    property int limitIndex: 0

    readonly property var battery: UPower.displayDevice
    readonly property real percent: (battery?.percentage ?? 0) * 100
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging

    readonly property var profiles: [
        { icon: "󰌪", label: "Saver", value: PowerProfile.PowerSaver },
        { icon: "󰊚", label: "Balanced", value: PowerProfile.Balanced },
        { icon: "󰓅", label: "Performance", value: PowerProfile.Performance }
    ]

    readonly property var limits: [
        { icon: "󰂃", label: "80%", value: 80 },
        { icon: "󰂄", label: "100%", value: 100 }
    ]

    property int chargeLimit: 100

    FileView {
        id: thresholdFile
        path: "/sys/class/power_supply/BAT0/charge_control_end_threshold"
        printErrors: false
        onLoaded: root.chargeLimit = parseInt(text().trim()) || 100
    }

    readonly property string timeText: {
        const secs = charging ? (battery?.timeToFull ?? 0) : (battery?.timeToEmpty ?? 0);
        if (secs <= 0)
            return "";
        const hours = Math.floor(secs / 3600);
        const minutes = Math.floor((secs % 3600) / 60);
        return (hours > 0 ? hours + "h " : "") + minutes + "m " + (charging ? "to full" : "left");
    }

    readonly property string degraded: {
        const reason = PowerProfiles.degradationReason;
        if (reason === PerformanceDegradationReason.LapDetected)
            return "Throttled: lap detected";
        if (reason === PerformanceDegradationReason.HighOperatingTemperature)
            return "Throttled: high temperature";
        return "";
    }

    function show(): void {
        thresholdFile.reload();
        root.groupIndex = 0;
        root.profileIndex = root.profiles.findIndex(p => p.value === PowerProfiles.profile);
        if (root.profileIndex < 0)
            root.profileIndex = 1;
        root.limitIndex = root.chargeLimit <= 80 ? 0 : 1;
        root.open = true;
    }

    function apply(): void {
        if (root.groupIndex === 0) {
            PowerProfiles.profile = root.profiles[root.profileIndex].value;
        } else {
            Quickshell.execDetached(["sudo", "set-charge-threshold", String(root.limits[root.limitIndex].value)]);
        }
        root.open = false;
    }

    IpcHandler {
        target: "powertuning"

        function toggle(): void {
            if (root.open)
                root.open = false;
            else
                root.show();
        }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell-powertuning"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Theme.scrimLight

            Item {
                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    const count = root.groupIndex === 0 ? root.profiles.length : root.limits.length;
                    if (event.key === Qt.Key_Escape) {
                        root.open = false;
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        root.groupIndex = 1;
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        root.groupIndex = 0;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                        if (root.groupIndex === 0)
                            root.profileIndex = (root.profileIndex + 1) % count;
                        else
                            root.limitIndex = (root.limitIndex + 1) % count;
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                        if (root.groupIndex === 0)
                            root.profileIndex = (root.profileIndex - 1 + count) % count;
                        else
                            root.limitIndex = (root.limitIndex - 1 + count) % count;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.apply();
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                }

                Rectangle {
                    anchors.centerIn: parent
                    implicitWidth: Theme.tuningWidth
                    implicitHeight: layout.implicitHeight + Theme.notifPadding * 2
                    color: Theme.notifBg
                    border.width: Theme.notifBorderSize
                    border.color: Theme.blue

                    Column {
                        id: layout
                        anchors.centerIn: parent
                        width: parent.width - Theme.notifPadding * 2
                        spacing: Theme.notifPadding

                        PanelHeader {
                            icon: "󰓅"
                            title: "Power tuning"
                            status: root.charging ? "Charging" : "On battery"
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.notifPadding

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.charging ? "󰂄" : "󰁹"
                                color: root.charging ? Theme.green : Theme.text
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.menuFontPointSize + 10
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: Math.round(root.percent) + "%"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.menuFontPointSize + 2
                                    font.bold: true
                                }

                                Text {
                                    visible: text !== ""
                                    text: root.timeText
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.dialogSmallPointSize
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: Theme.osdBarHeight
                            color: Theme.surface1

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * Math.min(1, root.percent / 100)
                                color: root.charging ? Theme.green : Theme.blue
                            }
                        }

                        Text {
                            visible: root.degraded !== ""
                            width: parent.width
                            text: root.degraded
                            color: Theme.yellow
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.dialogSmallPointSize
                        }

                        SegmentedRow {
                            width: parent.width
                            title: "Power profile"
                            entries: root.profiles
                            selected: root.profileIndex
                            focused: root.groupIndex === 0
                            onPicked: index => {
                                root.groupIndex = 0;
                                root.profileIndex = index;
                                root.apply();
                            }
                        }

                        SegmentedRow {
                            width: parent.width
                            title: "Charge limit"
                            entries: root.limits
                            selected: root.limitIndex
                            focused: root.groupIndex === 1
                            onPicked: index => {
                                root.groupIndex = 1;
                                root.limitIndex = index;
                                root.apply();
                            }
                        }

                        Text {
                            width: parent.width
                            text: "↑↓ group  ·  ←→ pick  ·  Enter  ·  Esc"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.dialogSmallPointSize
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }
}
