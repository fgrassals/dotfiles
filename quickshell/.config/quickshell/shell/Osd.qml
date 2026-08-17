import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs

Scope {
    id: root

    property string icon: ""
    property real value: 0
    property bool active: false
    property bool primed: false

    function show(newIcon: string, newValue: real): void {
        root.icon = newIcon;
        root.value = Math.max(0, Math.min(1, newValue));
        root.active = true;
        hideTimer.restart();
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null

        function onVolumeChanged() {
            if (root.primed && !ShellState.audioPanelOpen)
                root.show(volumeIcon(), Pipewire.defaultAudioSink.audio.volume);
        }

        function onMutedChanged() {
            if (root.primed && !ShellState.audioPanelOpen)
                root.show(volumeIcon(), Pipewire.defaultAudioSink.audio.volume);
        }
    }

    Connections {
        target: Pipewire.defaultAudioSource?.audio ?? null

        function onMutedChanged() {
            if (root.primed && !ShellState.audioPanelOpen)
                root.show(Pipewire.defaultAudioSource.audio.muted ? "󰍭" : "󰍬", Pipewire.defaultAudioSource.audio.volume);
        }
    }

    function volumeIcon(): string {
        const audio = Pipewire.defaultAudioSink?.audio;
        if (!audio || audio.muted)
            return "󰝟";
        const percent = audio.volume * 100;
        if (percent < 33)
            return "󰕿";
        if (percent < 66)
            return "󰖀";
        return "󰕾";
    }

    IpcHandler {
        target: "osd"

        function brightness(percent: string): void {
            root.show("󰃠", parseInt(percent) / 100);
        }
    }

    Timer {
        interval: 1500
        running: true
        onTriggered: root.primed = true
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: root.active = false
    }

    LazyLoader {
        active: root.active

        PanelWindow {
            anchors.bottom: true
            margins.bottom: screen.height / 6
            exclusiveZone: 0
            mask: Region {}

            implicitWidth: Theme.osdWidth
            implicitHeight: Theme.osdHeight
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Theme.notifBg
                border.width: Theme.notifBorderSize
                border.color: Theme.blue

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.notifPadding
                    anchors.rightMargin: Theme.notifPadding
                    spacing: Theme.notifPadding

                    Text {
                        text: root.icon
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.notifFontPointSize + 4
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Theme.meterHeight
                        color: Theme.surface1

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * root.value
                            color: Theme.blue
                        }
                    }

                    Text {
                        text: Math.round(root.value * 100) + "%"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.notifFontPointSize
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 44
                    }
                }
            }
        }
    }
}
