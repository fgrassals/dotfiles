pragma Singleton

import Quickshell
import QtQuick

// Catppuccin Macchiato
Singleton {
    // ---[ Palette ]-----------------------------------------------------------
    readonly property color bg: "#f7181926"      // crust @ 97%
    readonly property color pill: "#1e2030"      // mantle
    readonly property color text: "#cad3f5"
    readonly property color muted: "#6e738d"
    readonly property color blue: "#8aadf4"
    readonly property color green: "#a6da95"
    readonly property color yellow: "#eed49f"
    readonly property color red: "#ed8796"
    readonly property color peach: "#f5a97f"
    readonly property color surface1: "#363a4f"
    readonly property color hover: "#0fffffff"   // white @ 6% — hover wash

    // ---[ Type ]--------------------------------------------------------------
    readonly property string fontFamily: "CaskaydiaMono Nerd Font"
    readonly property int fontSize: 13

    // ---[ Metrics ]-----------------------------------------------------------
    readonly property int barHeight: 26
    readonly property int pillGap: 4
    readonly property int groupPadding: 2
    readonly property int itemPadding: 6
    readonly property int clockPadding: 12
    readonly property int trayIconSize: 14
    readonly property int traySpacing: 12
    readonly property int privacyPadding: 4
    readonly property int privacySpacing: 4
    readonly property color tooltipBg: "#000000"
    readonly property int tooltipPadding: 8
    readonly property int tooltipDelay: 400
}
