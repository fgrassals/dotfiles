pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property var data: JSON.parse(state.text() || "{}")
    readonly property int pacmanCount: Number(data.pacman ?? 0)
    readonly property int aurCount: Number(data.aur ?? 0)
    readonly property int miseCount: Number(data.mise ?? 0)
    readonly property int firmwareCount: Number(data.firmware ?? 0)
    readonly property string lastChecked: data.checked ?? ""

    readonly property int softwareCount: pacmanCount + aurCount + miseCount

    function refresh(): void {
        check.running = true;
    }

    // Written by the `updates-check` script.
    FileView {
        id: state
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/updates.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    Process {
        id: check
        command: ["updates-check"]
        onExited: state.reload()
    }
}
