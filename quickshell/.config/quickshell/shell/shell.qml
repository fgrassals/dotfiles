import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

ShellRoot {
    Wallpaper {}
    Osd {}
    Polkit {}
    PowerMenu {}
    PowerTuning {}
    AudioPanel {}
    BluetoothPanel {}
    NetworkPanel {}
    DisplayPanel {}
    KeybindPanel {}
    NotificationHistory {}
    UpdatesPanel {}

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: barWindow

                required property var modelData
                screen: modelData

                anchors {
                    left: true
                    right: true
                    top: true
                }

                implicitHeight: Theme.barHeight
                color: Theme.bg

                IdleInhibitor {
                    window: barWindow
                    enabled: ShellState.idleInhibited
                }

                Item {
                    anchors.fill: parent

                    RowLayout {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        spacing: Theme.pillGap

                        Clock {
                            Layout.fillHeight: true
                        }

                        Stats {
                            Layout.fillHeight: true
                        }

                        NotificationBell {
                            Layout.fillHeight: true
                        }

                        Updates {
                            Layout.fillHeight: true
                        }

                        Indicators {
                            Layout.fillHeight: true
                        }
                    }

                    RowLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        spacing: Theme.pillGap

                        Workspaces {
                            Layout.fillHeight: true
                            screen: modelData
                        }
                    }

                    RowLayout {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        spacing: Theme.pillGap

                        Status {
                            bar: barWindow
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
    }
}
