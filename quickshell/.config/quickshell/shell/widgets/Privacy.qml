import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    readonly property var nodes: Pipewire.nodes?.values ?? []

    // Requiring the Stream flag excludes idle hardware devices, leaving only
    // applications actively capturing.
    readonly property bool micActive: nodes.some(n => (n.type & PwNodeType.Audio) && (n.type & PwNodeType.Source) && (n.type & PwNodeType.Stream))
    readonly property bool screenActive: nodes.some(n => (n.type & PwNodeType.Video) && (n.type & PwNodeType.Stream))

    visible: micActive || screenActive
    implicitWidth: visible ? row.implicitWidth + Theme.privacyPadding * 2 : 0
    implicitHeight: Theme.barHeight

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
