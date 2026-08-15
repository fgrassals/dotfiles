import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root

    required property ShellScreen screen

    implicitWidth: row.implicitWidth + Theme.groupPadding * 2
    implicitHeight: Theme.barHeight
    color: Theme.pill

    RowLayout {
        id: row
        anchors.centerIn: parent
        height: parent.height
        spacing: 0

        Repeater {
            model: ScriptModel {
                values: root.screen ? Hyprland.workspaces.values.filter(ws => ws.monitor?.name === root.screen.name) : []
            }

            delegate: Rectangle {
                id: ws

                required property HyprlandWorkspace modelData

                Layout.fillHeight: true
                implicitWidth: label.implicitWidth + Theme.itemPadding * 2
                color: mouse.containsMouse ? Theme.hover : "transparent"

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: ws.modelData.id
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: ws.modelData.active || ws.modelData.urgent
                    color: {
                        if (ws.modelData.urgent) return Theme.red;
                        if (ws.modelData.active) return Theme.blue;
                        if (mouse.containsMouse) return Theme.text;
                        return Theme.muted;
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ws.modelData.activate()
                }
            }
        }
    }
}
