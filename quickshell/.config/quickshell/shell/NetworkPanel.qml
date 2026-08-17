import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import QtQuick
import qs

Scope {
    id: root

    readonly property bool open: ShellState.openPanel === "network"

    // Anchored to the network, not the index: the scan adds and drops rows.
    property var selectedNetwork: null
    readonly property int selectedIndex: {
        const i = root.rows.findIndex(r => r.network === root.selectedNetwork);
        return i >= 0 ? i : 0;
    }

    // The row actually highlighted; selectedNetwork is null until something is picked.
    readonly property var currentNetwork: root.rows[root.selectedIndex]?.network ?? null
    // Set only when this panel started the scan; never stops another client's.
    property bool startedScan: false

    // Network we asked to connect, watched for connectionFailed.
    property var pending: null
    property var pskTarget: null
    property bool pskAttempted: false
    property string errorText: ""
    property int shakeOffset: 0

    readonly property var devices: Networking.devices?.values ?? []
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: devices.find(d => d.type === DeviceType.Wired) ?? null

    readonly property bool hwBlocked: !Networking.wifiHardwareEnabled
    readonly property bool wifiOn: Networking.wifiEnabled && !root.hwBlocked

    readonly property var wifiNets: (root.wifiDevice?.networks?.values ?? []).filter(n => n.name !== "")
    readonly property var current: root.wifiNets.filter(n => n.connected)
    readonly property var saved: root.wifiNets.filter(n => !n.connected && n.known).sort(root.byRank)
    readonly property var available: root.wifiNets.filter(n => !n.connected && !n.known).sort(root.byRank).slice(0, Theme.networkMaxRows)

    // Rank is captured once per network; live signal sorting would reshuffle rows.
    property var rank: ({})
    readonly property string membership: root.wifiNets.map(n => n.name).sort().join("\u0000")

    // The unplugged wired row is rendered but absent here, so arrows skip it.
    readonly property var wiredNetwork: (root.wiredDevice?.hasLink ?? false) ? root.wiredDevice.network : null
    readonly property int wiredCount: root.wiredNetwork ? 1 : 0
    readonly property int netOffset: root.wiredCount

    readonly property var rows: {
        const list = [];
        if (root.wiredNetwork)
            list.push({ kind: "net", network: root.wiredNetwork });
        for (const n of root.current)
            list.push({ kind: "net", network: n });
        for (const n of root.saved)
            list.push({ kind: "net", network: n });
        for (const n of root.available)
            list.push({ kind: "net", network: n });
        return list;
    }

    readonly property string enterVerb: root.currentNetwork?.connected ? "disconnect" : "connect"

    function bySignal(a, b): int {
        return (b.signalStrength ?? 0) - (a.signalStrength ?? 0);
    }

    function byRank(a, b): int {
        return (root.rank[a.name] ?? 9999) - (root.rank[b.name] ?? 9999);
    }

    function captureOrder(): void {
        const map = {};
        let next = 0;
        for (const key in root.rank) {
            map[key] = root.rank[key];
            next = Math.max(next, root.rank[key] + 1);
        }
        for (const n of root.wifiNets.slice().sort(root.bySignal))
            if (map[n.name] === undefined)
                map[n.name] = next++;
        root.rank = map;
    }

    function signalIcon(strength: real): string {
        const icons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"];
        return icons[Math.min(4, Math.floor((strength ?? 0) * 5))];
    }

    function isSecured(network): bool {
        return network?.security !== undefined && network.security !== WifiSecurityType.Open;
    }

    function activate(): void {
        const network = root.currentNetwork;
        if (!network)
            return;
        if (network.connected) {
            network.disconnect();
            return;
        }
        root.errorText = "";
        root.pskAttempted = false;
        root.pending = network;
        network.connect();
    }

    function forgetSelected(): void {
        const network = root.currentNetwork;
        if (network?.known)
            network.forget();
    }

    function toggleWifi(): void {
        if (!root.hwBlocked)
            Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    // Closes first; the panel holds exclusive keyboard focus.
    function editConnections(): void {
        ShellState.close();
        Quickshell.execDetached(["kitty", "--class=floating-tui", "-e", "nmtui"]);
    }

    function submitPsk(psk: string): void {
        if (!root.pskTarget)
            return;
        root.pskAttempted = true;
        root.errorText = "";
        root.pending = root.pskTarget;
        root.pskTarget.connectWithPsk(psk);
    }

    function cancelPsk(): void {
        root.pskTarget = null;
        root.pending = null;
        root.pskAttempted = false;
        root.errorText = "";
    }

    function moveSelection(delta: int): void {
        const count = root.rows.length;
        if (count === 0)
            return;
        root.selectedNetwork = root.rows[(root.selectedIndex + delta + count) % count]?.network ?? null;
    }

    onOpenChanged: {
        if (root.open) {
            root.selectedNetwork = null;
            root.rank = ({});
            root.cancelPsk();
        }
        scanSettle.restart();
    }
    onMembershipChanged: if (root.open) root.captureOrder()

    Connections {
        target: root.pending ?? null

        function onConnectionFailed(reason: int): void {
            if (reason === ConnectionFailReason.NoSecrets) {
                root.pskTarget = root.pending;
                if (root.pskAttempted) {
                    root.errorText = "Wrong password";
                    shake.restart();
                }
            } else {
                root.errorText = ConnectionFailReason.toString(reason);
                root.pending = null;
            }
        }

        function onConnectedChanged(): void {
            if (root.pending?.connected)
                root.cancelPsk();
        }
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: root; property: "shakeOffset"; to: -8; duration: 35; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 8; duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 55; easing.type: Easing.OutQuad }
    }

    // Debounced so rapid open/close coalesces into one scan request.
    Timer {
        id: scanSettle
        interval: 300
        onTriggered: {
            if (!root.wifiDevice)
                return;
            if (root.open) {
                if (root.wifiOn && !root.wifiDevice.scannerEnabled) {
                    root.wifiDevice.scannerEnabled = true;
                    root.startedScan = true;
                }
            } else if (root.startedScan && root.wifiDevice.scannerEnabled) {
                root.wifiDevice.scannerEnabled = false;
                root.startedScan = false;
            }
        }
    }

    IpcHandler {
        target: "network"

        function toggle(): void {
            ShellState.toggle("network");
        }
    }

    LazyLoader {
        active: root.open

        PanelFrame {
            namespace: "quickshell-network"
            offset: root.shakeOffset
            interceptEscape: root.pskTarget !== null

            onCloseRequested: ShellState.close()

            onKeyPressed: event => {
                const count = root.rows.length;
                if (root.pskTarget) {
                    if (event.key === Qt.Key_Escape) {
                        root.cancelPsk();
                        event.accepted = true;
                    }
                    return;
                }
                if (event.key === Qt.Key_W) {
                    root.toggleWifi();
                } else if (event.key === Qt.Key_E) {
                    root.editConnections();
                } else if (count === 0) {
                    return;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    root.moveSelection(1);
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    root.moveSelection(-1);
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activate();
                } else if (event.key === Qt.Key_F) {
                    root.forgetSelected();
                } else {
                    return;
                }
                event.accepted = true;
            }

            PanelHeader {
                icon: root.wiredDevice?.connected ? "󱘖" : root.wifiOn ? "󰤨" : "󰤮"
                iconColor: root.wifiOn || root.wiredDevice?.connected ? Theme.blue : Theme.muted
                title: "Network"
                status: {
                    if (root.hwBlocked)
                        return "Blocked by hardware";
                    if (!Networking.wifiEnabled && !root.wiredDevice?.connected)
                        return "Off";
                    if (Networking.connectivity === NetworkConnectivity.Portal)
                        return "Captive portal";
                    if (Networking.connectivity === NetworkConnectivity.Limited)
                        return "No internet";
                    return "";
                }
            }

            SectionHeader {
                width: parent.width
                visible: root.wiredDevice !== null
                text: "Wired"
            }

            PanelRow {
                width: parent.width
                visible: root.wiredDevice !== null
                icon: "󰈀"
                title: root.wiredNetwork?.name ?? root.wiredDevice?.name ?? ""
                detail: {
                    if (!root.wiredDevice?.hasLink)
                        return "No cable";
                    if (root.wiredDevice?.connected)
                        return (root.wiredDevice?.linkSpeed ?? 0) + " Mb/s";
                    return "";
                }
                active: root.wiredDevice?.connected ?? false
                dimmed: !(root.wiredDevice?.hasLink ?? false)
                focused: root.wiredNetwork !== null && root.selectedIndex === 0
                onPicked: root.selectedNetwork = root.wiredNetwork
            }

            SectionHeader {
                width: parent.width
                text: "Current"
            }

            Text {
                visible: root.current.length === 0
                width: parent.width
                text: Networking.wifiEnabled ? "Not connected" : "Wi-Fi off"
                leftPadding: Theme.itemPadding
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                font.italic: true
            }

            Repeater {
                model: root.current

                delegate: PanelRow {
                    required property int index
                    required property var modelData

                    width: parent.width
                    icon: root.signalIcon(modelData.signalStrength)
                    title: modelData.name
                    detail: Math.round((modelData.signalStrength ?? 0) * 100) + "%"
                    secured: root.isSecured(modelData)
                    active: true
                    focused: (root.netOffset + index) === root.selectedIndex
                    onPicked: root.selectedNetwork = modelData
                }
            }

            SectionHeader {
                width: parent.width
                visible: root.saved.length > 0
                text: "Saved"
            }

            Repeater {
                model: root.saved

                delegate: PanelRow {
                    required property int index
                    required property var modelData

                    readonly property int rowIndex: root.netOffset + root.current.length + index

                    width: parent.width
                    icon: root.signalIcon(modelData.signalStrength)
                    title: modelData.name
                    detail: modelData.stateChanging ? "Connecting…" : Math.round((modelData.signalStrength ?? 0) * 100) + "%"
                    secured: root.isSecured(modelData)
                    focused: rowIndex === root.selectedIndex
                    onPicked: root.selectedNetwork = modelData
                }
            }

            SectionHeader {
                width: parent.width
                text: "Available"
            }

            Text {
                visible: root.available.length === 0
                width: parent.width
                text: !root.wifiOn ? "Wi-Fi off" : root.wifiDevice?.scannerEnabled ? "Scanning…" : "Nothing found"
                leftPadding: Theme.itemPadding
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                font.italic: true
            }

            Repeater {
                model: root.available

                delegate: PanelRow {
                    required property int index
                    required property var modelData

                    readonly property int rowIndex: root.netOffset + root.current.length + root.saved.length + index

                    width: parent.width
                    icon: root.signalIcon(modelData.signalStrength)
                    title: modelData.name
                    detail: modelData.stateChanging ? "Connecting…" : Math.round((modelData.signalStrength ?? 0) * 100) + "%"
                    secured: root.isSecured(modelData)
                    focused: rowIndex === root.selectedIndex
                    onPicked: root.selectedNetwork = modelData
                }
            }

            Rectangle {
                width: parent.width
                implicitHeight: Theme.fieldHeight
                visible: root.pskTarget !== null
                color: Theme.bg
                border.width: 1
                border.color: root.errorText !== "" ? Theme.red : Theme.blue

                onVisibleChanged: if (visible) psk.forceActiveFocus()

                TextInput {
                    id: psk
                    anchors.fill: parent
                    anchors.leftMargin: Theme.itemPadding
                    anchors.rightMargin: Theme.itemPadding
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    color: root.errorText !== "" ? Theme.red : Theme.text
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.dialogSmallPointSize
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    selectByMouse: true
                    cursorVisible: activeFocus

                    onAccepted: {
                        root.submitPsk(text);
                        text = "";
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.itemPadding
                    anchors.verticalCenter: parent.verticalCenter
                    visible: psk.text === ""
                    text: root.errorText !== "" ? root.errorText : "Password for " + (root.pskTarget?.name ?? "")
                    color: root.errorText !== "" ? Theme.red : Theme.muted
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.dialogSmallPointSize
                    elide: Text.ElideRight
                    width: parent.width - Theme.itemPadding * 2
                }
            }

            Text {
                width: parent.width
                visible: root.pskTarget === null && root.errorText !== ""
                text: root.errorText
                color: Theme.red
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
            }

            Text {
                width: parent.width
                text: root.pskTarget ? "⏎ connect · Esc cancel" : "↑↓ · ⏎ " + root.enterVerb + " · f forget · w wi-fi · Esc"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.dialogSmallPointSize
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
