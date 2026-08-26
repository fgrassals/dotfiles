import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root

    readonly property var nodes: Pipewire.nodes?.values ?? []
    readonly property bool micActive: nodes.some(n => n.type === PwNodeType.AudioInStream && n.name !== "quickshell")
    readonly property bool screenActive: nodes.some(n => n.properties?.["media.class"] === "Stream/Input/Video")

    // Binds the nodes so `properties` is populated.
    PwObjectTracker {
        objects: root.nodes
    }

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
