import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs

Scope {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.local/share/wallpaper.jpg"
    property int revision: 0

    readonly property string source: "file://" + path + "?v=" + revision

    IpcHandler {
        target: "wallpaper"

        function reload(): void {
            root.revision++;
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.namespace: "quickshell-wallpaper"
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                color: Theme.bg
                mask: Region {}

                Image {
                    anchors.fill: parent
                    source: root.source
                    fillMode: Image.PreserveAspectCrop
                    // decode at panel resolution, not the source file's
                    sourceSize.width: Math.round(modelData.width * modelData.devicePixelRatio)
                    sourceSize.height: Math.round(modelData.height * modelData.devicePixelRatio)
                    cache: false
                    asynchronous: true
                    smooth: true
                }
            }
        }
    }
}
