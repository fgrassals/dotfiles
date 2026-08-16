import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root

    readonly property var nodes: Pipewire.nodes?.values ?? []
    readonly property bool micActive: nodes.some(n => n.type === PwNodeType.AudioInStream)

    property bool screenActive: false

    Process {
        id: videoProbe
        command: ["sh", "-c", "pw-dump | jq '[.[] | select(.info.props.\"media.class\" == \"Stream/Input/Video\")] | length'"]
        stdout: StdioCollector {
            onStreamFinished: root.screenActive = parseInt(this.text.trim()) > 0
        }
    }

    readonly property int nodeCount: nodes.length
    onNodeCountChanged: videoProbe.running = true
    Component.onCompleted: videoProbe.running = true

    visible: micActive || screenActive
    implicitWidth: visible ? row.implicitWidth + Theme.privacyPadding * 2 : 0
    implicitHeight: Theme.barHeight
    color: Theme.pill

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.privacySpacing

        Text {
            visible: root.screenActive
            text: "󰍹"
            color: Theme.red
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            visible: root.micActive
            text: "󰍬"
            color: Theme.peach
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            verticalAlignment: Text.AlignVCenter
        }
    }
}
