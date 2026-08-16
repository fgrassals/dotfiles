import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root

    required property var bar

    implicitWidth: row.implicitWidth + Theme.groupPadding * 2
    implicitHeight: Theme.barHeight
    color: Theme.pill

    RowLayout {
        id: row
        anchors.centerIn: parent
        height: parent.height
        spacing: 0

        Tray {
            bar: root.bar
            Layout.fillHeight: true
        }

        GtkTheme { Layout.fillHeight: true }
        Nightlight { Layout.fillHeight: true }
        IdleToggle { Layout.fillHeight: true }
        Bluetooth { Layout.fillHeight: true }
        Network { Layout.fillHeight: true }
        Audio { Layout.fillHeight: true }
        Battery { Layout.fillHeight: true }
        Power { Layout.fillHeight: true }
    }
}
