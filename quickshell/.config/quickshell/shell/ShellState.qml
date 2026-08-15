pragma Singleton

import Quickshell

// Shared state for widgets that exist once per monitor but represent one setting.
Singleton {
    property bool idleInhibited: false
}
