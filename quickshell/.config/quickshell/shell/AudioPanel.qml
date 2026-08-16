import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import qs

Scope {
    id: root

    property bool open: false
    property int selectedIndex: 0

    onOpenChanged: ShellState.audioPanelOpen = open

    readonly property var allNodes: Pipewire.nodes?.values ?? []
    readonly property var sinks: allNodes.filter(n => n.type === PwNodeType.AudioSink && !n.isMonitor)
    readonly property var outStreams: allNodes.filter(n => n.type === PwNodeType.AudioOutStream)
    readonly property var sources: allNodes.filter(n => n.type === PwNodeType.AudioSource && !n.isMonitor)
    readonly property var inStreams: allNodes.filter(n => n.type === PwNodeType.AudioInStream)

    readonly property var rows: {
        const list = [];
        for (const n of root.sinks)
            list.push({ node: n, kind: "sink", section: "Output" });
        for (const n of root.outStreams)
            list.push({ node: n, kind: "stream", section: "Playing" });
        for (const n of root.sources)
            list.push({ node: n, kind: "source", section: "Input" });
        for (const n of root.inStreams)
            list.push({ node: n, kind: "instream", section: "Recording" });
        return list;
    }

    PwObjectTracker {
        objects: root.rows.map(r => r.node)
    }

    function label(node): string {
        return node?.description || node?.nickname || node?.name || "";
    }

    function adjust(delta: real): void {
        const row = root.rows[root.selectedIndex];
        if (!row?.node?.audio)
            return;
        row.node.audio.volume = Math.max(0, Math.min(1, row.node.audio.volume + delta));
    }

    function toggleMute(): void {
        const row = root.rows[root.selectedIndex];
        if (!row?.node?.audio)
            return;
        row.node.audio.muted = !row.node.audio.muted;
    }

    function makeDefault(): void {
        const row = root.rows[root.selectedIndex];
        if (row?.kind === "sink")
            Pipewire.preferredDefaultAudioSink = row.node;
        else if (row?.kind === "source")
            Pipewire.preferredDefaultAudioSource = row.node;
    }

    function show(): void {
        root.selectedIndex = 0;
        root.open = true;
    }

    IpcHandler {
        target: "audio"

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
            WlrLayershell.namespace: "quickshell-audio"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Theme.scrimLight

            Item {
                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    const count = root.rows.length;
                    if (event.key === Qt.Key_Escape) {
                        root.open = false;
                    } else if (count === 0) {
                        return;
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        root.selectedIndex = (root.selectedIndex + 1) % count;
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        root.selectedIndex = (root.selectedIndex - 1 + count) % count;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                        root.adjust(0.05);
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                        root.adjust(-0.05);
                    } else if (event.key === Qt.Key_M) {
                        root.toggleMute();
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.makeDefault();
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
                    implicitWidth: Theme.audioWidth
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
                            icon: Pipewire.defaultAudioSink?.audio?.muted ? "󰝟" : "󰕾"
                            title: "Audio"
                            status: Pipewire.defaultAudioSink?.audio?.muted ? "Output muted" : ""
                        }

                        Repeater {
                            model: root.rows

                            delegate: Column {
                                id: entry

                                required property int index
                                required property var modelData

                                readonly property bool startsSection: index === 0 || root.rows[index - 1].section !== modelData.section

                                width: layout.width
                                spacing: 4
                                topPadding: startsSection && index > 0 ? Theme.itemPadding : 0

                                SectionHeader {
                                    visible: entry.startsSection
                                    width: entry.width
                                    text: entry.modelData.section
                                }

                                AudioRow {
                                    width: entry.width
                                    node: entry.modelData.node
                                    kind: entry.modelData.kind
                                    title: root.label(entry.modelData.node)
                                    isDefault: (entry.modelData.kind === "sink" && entry.modelData.node === Pipewire.defaultAudioSink)
                                        || (entry.modelData.kind === "source" && entry.modelData.node === Pipewire.defaultAudioSource)
                                    focused: entry.index === root.selectedIndex
                                    onPicked: root.selectedIndex = entry.index
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: "↑↓ row  ·  ←→ volume  ·  m mute  ·  Enter default  ·  Esc"
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
