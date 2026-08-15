import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import qs

Text {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    verticalAlignment: Text.AlignVCenter
    leftPadding: Theme.itemPadding
    rightPadding: Theme.itemPadding
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    text: {
        if (muted)
            return "󰝟";
        const percent = volume * 100;
        if (percent < 33)
            return "󰕿";
        if (percent < 66)
            return "󰖀";
        return "󰕾";
    }

    color: mouse.containsMouse ? Theme.blue : muted ? Theme.muted : Theme.text

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: event => {
            if (event.button === Qt.RightButton) {
                if (root.sink?.audio)
                    root.sink.audio.muted = !root.sink.audio.muted;
            } else {
                Quickshell.execDetached(["kitty", "--class=floating-tui", "-e", "wiremix"]);
            }
        }

        onWheel: event => {
            if (!root.sink?.audio)
                return;
            const step = event.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step));
        }
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        label: Math.round(root.volume * 100) + "%  —  " + (root.sink?.description || root.sink?.nickname || root.sink?.name || "")
    }
}
