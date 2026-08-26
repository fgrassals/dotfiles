import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Polkit
import QtQuick
import qs

Scope {
    id: root

    property bool closing: false
    property bool submitted: false
    property bool errorFlash: false
    property bool fingerprintConfigured: false
    property bool lidClosed: false
    property string fingerprintHint: ""
    property int shakeOffset: 0

    readonly property bool dialogVisible: agent.isActive || closing
    readonly property bool fingerprintAvailable: fingerprintConfigured && !lidClosed
    readonly property bool responseRequired: agent.flow?.isResponseRequired ?? false
    readonly property string stage: responseRequired || submitted || !fingerprintAvailable ? "password" : "fingerprint"

    onSubmittedChanged: if (submitted) checkingTimeout.restart()

    function authorizationLabel(message: string): string {
        const match = /^Authentication is (?:needed|required) to run [`']([^`']+)[`'] as /i.exec(message ?? "");
        return match ? "Authorize running '" + match[1] + "'" : message ?? "";
    }

    function beginClose() {
        root.closing = true;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: {
            root.closing = false;
            root.submitted = false;
            root.errorFlash = false;
        }
    }

    Timer {
        id: checkingTimeout
        interval: 4000
        onTriggered: root.submitted = false
    }

    Timer {
        id: errorTimer
        interval: 4000
        onTriggered: root.errorFlash = false
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: root; property: "shakeOffset"; to: -8; duration: 35; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 8; duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 55; easing.type: Easing.OutQuad }
    }

    FileView {
        path: "/etc/pam.d/polkit-1"
        watchChanges: true
        printErrors: false
        onLoaded: root.fingerprintConfigured = /^auth\s+.*pam_fprintd\.so/m.test(text())
        onLoadFailed: root.fingerprintConfigured = false
        onFileChanged: reload()
    }

    FileView {
        id: lidState
        path: "/proc/acpi/button/lid/LID/state"
        printErrors: false
        onLoaded: root.lidClosed = text().indexOf("closed") !== -1
        onLoadFailed: root.lidClosed = false
    }

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            closeTimer.stop();
            root.closing = false;
            root.submitted = false;
            root.errorFlash = false;
            root.fingerprintHint = "";
            lidState.reload();
        }
    }

    Connections {
        target: agent.flow ?? null

        function onAuthenticationFailed() {
            root.submitted = false;
            root.errorFlash = true;
            errorTimer.restart();
            shake.restart();
        }

        function onAuthenticationSucceeded() {
            root.beginClose();
        }

        function onAuthenticationRequestCancelled() {
            root.beginClose();
        }

        function onIsResponseRequiredChanged() {
            if (agent.flow?.isResponseRequired)
                root.submitted = false;
        }

        function onSupplementaryMessageChanged() {
            const message = agent.flow?.supplementaryMessage ?? "";
            if (message !== "" && root.stage === "fingerprint")
                root.fingerprintHint = message;
        }
    }

    LazyLoader {
        active: root.dialogVisible

        PanelWindow {
            id: window

            screen: ShellState.focusedScreen

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell-polkit"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Theme.scrim

            function applyFocus() {
                if (root.stage === "fingerprint")
                    keyCatcher.forceActiveFocus();
                else
                    field.forceActiveFocus();
            }

            Component.onCompleted: Qt.callLater(applyFocus)

            Connections {
                target: root
                function onStageChanged() {
                    Qt.callLater(window.applyFocus);
                }
            }

            Item {
                id: keyCatcher
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: event => {
                    agent.flow?.cancelAuthenticationRequest();
                    root.beginClose();
                    event.accepted = true;
                }

                Rectangle {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: root.shakeOffset
                    implicitWidth: Theme.notifWidth
                    implicitHeight: layout.implicitHeight + Theme.notifPadding * 2
                    color: Theme.notifBg
                    border.width: Theme.notifBorderSize
                    border.color: root.errorFlash ? Theme.red : Theme.blue

                    Column {
                        id: layout
                        anchors.centerIn: parent
                        width: parent.width - Theme.notifPadding * 2
                        spacing: Theme.notifPadding

                        Text {
                            width: parent.width
                            text: root.authorizationLabel(agent.flow?.message ?? "")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.notifFontPointSize
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            visible: root.errorFlash
                            text: "Wrong password"
                            color: Theme.red
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.notifFontPointSize
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.itemPadding
                            visible: root.stage === "fingerprint"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰈷"
                                color: Theme.blue
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.notifFontPointSize + 6
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - parent.spacing - 30
                                visible: text !== ""
                                text: root.fingerprintHint
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.notifFontPointSize
                                wrapMode: Text.WordWrap
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 6
                            visible: root.stage === "password"

                            Text {
                                text: "Password"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.dialogSmallPointSize
                            }

                            Rectangle {
                                width: parent.width
                                implicitHeight: Theme.fieldHeight
                                color: Theme.bg
                                border.width: 1
                                border.color: root.errorFlash ? Theme.red : field.activeFocus ? Theme.blue : Theme.surface1

                                TextInput {
                                    id: field
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.itemPadding
                                    anchors.rightMargin: Theme.itemPadding
                                    verticalAlignment: TextInput.AlignVCenter
                                    clip: true
                                    color: root.errorFlash ? Theme.red : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.notifFontPointSize
                                    echoMode: agent.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                                    passwordCharacter: "•"
                                    selectByMouse: true
                                    cursorVisible: activeFocus

                                    onAccepted: {
                                        if (!root.responseRequired)
                                            return;
                                        root.submitted = true;
                                        root.errorFlash = false;
                                        agent.flow?.submit(text);
                                        text = "";
                                    }

                                    Keys.onEscapePressed: event => {
                                        agent.flow?.cancelAuthenticationRequest();
                                        root.beginClose();
                                        event.accepted = true;
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.itemPadding
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: field.text === ""
                                    text: root.submitted ? "Checking…" : "Enter password"
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.notifFontPointSize
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: root.stage === "fingerprint" ? "Esc to cancel" : "Enter to confirm  ·  Esc to cancel"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.dialogSmallPointSize
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }
}
