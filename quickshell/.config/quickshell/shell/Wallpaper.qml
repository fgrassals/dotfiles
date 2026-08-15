import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs

Scope {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.local/share/wallpaper.jpg"
    property int revision: 0

    // Qt caches by URL, so the same path with new content renders stale.
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
                    cache: false
                    asynchronous: true
                    smooth: true
                }
            }
        }
    }
}
