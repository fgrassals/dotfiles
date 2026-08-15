import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    required property var bar

    implicitWidth: row.implicitWidth + Theme.itemPadding * 2
    implicitHeight: Theme.barHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.traySpacing

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: entry

                required property SystemTrayItem modelData

                implicitWidth: Theme.trayIconSize
                implicitHeight: Theme.trayIconSize

                Image {
                    anchors.fill: parent
                    source: entry.modelData.icon
                    sourceSize.width: Theme.trayIconSize
                    sourceSize.height: Theme.trayIconSize
                    smooth: true
                }

                MouseArea {
                    id: entryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                    onClicked: event => {
                        if (event.button === Qt.MiddleButton)
                            entry.modelData.secondaryActivate();
                        else if (event.button === Qt.RightButton)
                            entry.modelData.display(root.bar, entry.x, entry.y);
                        else
                            entry.modelData.activate();
                    }

                    onWheel: event => entry.modelData.scroll(event.angleDelta.y, false)
                }

                Tooltip {
                    target: entry
                    hovered: entryMouse.containsMouse
                    label: entry.modelData.tooltipTitle || entry.modelData.title || entry.modelData.id
                }
            }
        }
    }
}
