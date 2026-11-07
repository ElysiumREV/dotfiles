import "../.." as Config
import "../../services" as Services
import "../../widgets" as Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire

Rectangle {
    required property var menu
    visible: Services.BluetoothControl.expanded
    Layout.fillWidth: true
    implicitHeight: bluetoothColumn.implicitHeight + 20
    radius: Config.Theme.radiusControl
    color: bluetoothHover.hovered ? Config.Theme.alpha(Config.Theme.colTextSec, 0.18) : Config.Theme.alpha(Config.Theme.colTextSec, 0.1)

    HoverHandler { id: bluetoothHover }

    ColumnLayout {
        id: bluetoothColumn

        spacing: Config.Theme.spaceSm
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: bluetoothHeader.implicitHeight

            RowLayout {
                id: bluetoothHeader
                anchors.fill: parent

            Text {
                text: "bluetooth"
                color: Services.BluetoothControl.enabled ? Config.Theme.colHighlight : Config.Theme.colMuted

                font {
                    family: "Material Symbols Rounded"
                    pixelSize: Config.Theme.iconSizeLg
                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "Bluetooth"
                    color: Config.Theme.colFg

                    font {
                        family: Config.Theme.fontFamily
                        pixelSize: Config.Theme.fontSize
                        bold: true
                    }

                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        if (!Services.BluetoothControl.enabled)
                            return Services.BluetoothControl.blocked ? "Blocked by the system" : "Disabled";

                        if (Services.BluetoothControl.connected.length > 0)
                            return Services.BluetoothControl.connected.length + " connected";

                        return "No connected devices";
                    }
                    color: Config.Theme.colMuted
                    elide: Text.ElideRight

                    font {
                        family: Config.Theme.fontFamily
                        pixelSize: Config.Theme.fontSizeSmall
                    }

                }

            }

            Text {
                text: Services.BluetoothControl.enabled ? (Services.BluetoothControl.expanded ? "expand_less" : "expand_more") : ""
                color: Config.Theme.colMuted

                font {
                    family: "Material Symbols Rounded"
                    pixelSize: Config.Theme.iconSizeMd
                }

            }

            Rectangle {
                id: bluetoothToggle
                Layout.preferredWidth: 38
                Layout.preferredHeight: 22
                radius: height / 2
                color: Services.BluetoothControl.enabled ? Config.Theme.alpha(Config.Theme.colHighlight, 0.45) : Config.Theme.alpha(Config.Theme.colTextSec, 0.35)

                Rectangle {
                    x: Services.BluetoothControl.enabled ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    radius: height / 2
                    color: Services.BluetoothControl.enabled ? Config.Theme.colHighlight : Config.Theme.colFg
                    Behavior on x { NumberAnimation { duration: 140 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.BluetoothControl.toggle()
                }
            }

            }

            MouseArea {
                anchors.fill: parent
                z: -1
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.BluetoothControl.toggleExpanded()
            }
        }

            ColumnLayout {
                Layout.fillWidth: true
                visible: Services.BluetoothControl.expanded && Services.BluetoothControl.enabled
            spacing: Config.Theme.spaceXs
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Config.Theme.alpha(Config.Theme.colTextSec, 0.2)
            }

            Text {
                Layout.fillWidth: true
                visible: Services.BluetoothPairingAgent.status !== ""
                text: Services.BluetoothPairingAgent.status
                color: Services.BluetoothPairingAgent.ready ? Config.Theme.colMuted : Config.Theme.colYellow
                wrapMode: Text.Wrap
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeCaption
            }

            Rectangle {
                Layout.fillWidth: true
                visible: Services.BluetoothPairingAgent.promptType !== ""
                implicitHeight: bluetoothAgentPrompt.implicitHeight + 16
                radius: Config.Theme.radiusControl
                color: Config.Theme.alpha(Config.Theme.colHighlight, 0.12)

                ColumnLayout {
                    id: bluetoothAgentPrompt
                    anchors.fill: parent
                    anchors.margins: Config.Theme.spaceSm
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: Services.BluetoothPairingAgent.promptText
                        color: Config.Theme.colFg
                        wrapMode: Text.Wrap
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeCaption
                    }

                    Widgets.ThemedTextField {
                        id: bluetoothPinInput
                        Layout.fillWidth: true
                        visible: Services.BluetoothPairingAgent.promptType === "pin"
                        placeholderText: "PIN or code"
                        horizontalTextPadding: 6
                        inputMethodHints: Qt.ImhDigitsOnly
                        font.pixelSize: Config.Theme.fontSizeCaption
                        onVisibleChanged: if (visible) forceActiveFocus()
                        Keys.onReturnPressed: {
                            Services.BluetoothPairingAgent.answerPrompt(text);
                            text = "";
                        }
                        background: Rectangle {
                            radius: Config.Theme.radiusSmall
                            color: Config.Theme.alpha(Config.Theme.colTextSec, 0.14)
                            border.width: 1
                            border.color: Config.Theme.alpha(Config.Theme.colTextSec, 0.25)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Config.Theme.spaceSm
                        Item { Layout.fillWidth: true }

                        Text {
                            text: Services.BluetoothPairingAgent.promptType === "display" ? "OK" : "Decline"
                            color: activeFocus ? Config.Theme.colFg : Config.Theme.colMuted
                            font.underline: activeFocus
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeCaption
                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: text === "OK" ? "Accept Bluetooth confirmation" : "Decline Bluetooth pairing"
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                        || event.key === Qt.Key_Space) {
                                    Services.BluetoothPairingAgent.cancelPrompt();
                                    event.accepted = true;
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Services.BluetoothPairingAgent.cancelPrompt()
                            }
                        }

                        Text {
                            visible: Services.BluetoothPairingAgent.promptType === "confirm"
                            text: "Confirm"
                            color: Config.Theme.colHighlight
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeCaption
                            font.bold: true
                            font.underline: activeFocus
                            activeFocusOnTab: visible
                            Accessible.role: Accessible.Button
                            Accessible.name: "Confirm Bluetooth pairing"
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                        || event.key === Qt.Key_Space) {
                                    Services.BluetoothPairingAgent.answerPrompt("yes");
                                    event.accepted = true;
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Services.BluetoothPairingAgent.answerPrompt("yes")
                            }
                        }

                        Text {
                            visible: Services.BluetoothPairingAgent.promptType === "pin"
                            text: "Send"
                            color: Config.Theme.colHighlight
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeCaption
                            font.bold: true
                            font.underline: activeFocus
                            activeFocusOnTab: visible
                            Accessible.role: Accessible.Button
                            Accessible.name: "Send Bluetooth code"
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                        || event.key === Qt.Key_Space) {
                                    Services.BluetoothPairingAgent.answerPrompt(bluetoothPinInput.text);
                                    bluetoothPinInput.text = "";
                                    event.accepted = true;
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Services.BluetoothPairingAgent.answerPrompt(bluetoothPinInput.text);
                                    bluetoothPinInput.text = "";
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: Services.BluetoothControl.devices.length === 0
                Layout.fillWidth: true
                text: Services.BluetoothControl.scanning ? "Searching for devices…" : "No known devices"
                color: Config.Theme.colMuted
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
                bottomPadding: 8
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeCaption
            }

            Flickable {
                id: bluetoothDevicesFlickable
                Layout.fillWidth: true
                visible: Services.BluetoothControl.devices.length > 0
                implicitHeight: Math.min(bluetoothDeviceRows.implicitHeight, menu.bluetoothMaxHeight)
                contentWidth: width
                contentHeight: bluetoothDeviceRows.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                ScrollBar.vertical: Widgets.ThemeScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Column {
                    id: bluetoothDeviceRows
                    width: bluetoothDevicesFlickable.width
                    spacing: 2

                    Repeater {
                        model: Services.BluetoothControl.devices

                        delegate: Rectangle {
                    id: bluetoothDeviceDelegate
                    required property var modelData

                    width: bluetoothDeviceRows.width
                    implicitHeight: 46
                    height: implicitHeight
                    radius: Config.Theme.radiusControl
                    activeFocusOnTab: Services.BluetoothControl.busyAddress !== modelData.address
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.name
                        + (Services.BluetoothControl.isConnected(modelData.address)
                           ? ", connected" : ", Bluetooth device")
                    color: activeFocus
                        ? Config.Theme.alpha(Config.Theme.colHighlight, Config.Theme.stateSelectedOpacity)
                        : (bluetoothDeviceMouse.containsMouse
                            ? Config.Theme.alpha(Config.Theme.colTextSec, Config.Theme.stateHoverOpacity)
                            : "transparent")
                    border.width: activeFocus ? 1 : 0
                    border.color: Config.Theme.colHighlight

                    onActiveFocusChanged: {
                        if (activeFocus)
                            menu.revealNetworkRow(this, bluetoothDevicesFlickable);
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                || event.key === Qt.Key_Space) {
                            if (Services.BluetoothControl.isConnected(modelData.address))
                                Services.BluetoothControl.disconnectDevice(modelData.address);
                            else if (modelData.paired)
                                Services.BluetoothControl.connectDevice(modelData.address);
                            else
                                Services.BluetoothControl.pairDevice(modelData.address);
                            event.accepted = true;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: Config.Theme.spaceSm
                        Text {
                            text: Services.BluetoothControl.isConnected(modelData.address) ? "bluetooth_connected" : "bluetooth"
                            color: Services.BluetoothControl.isConnected(modelData.address) ? Config.Theme.colHighlight : Config.Theme.colFg

                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: Config.Theme.iconSizeSm
                            }

                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: Config.Theme.colFg
                                elide: Text.ElideRight

                                font {
                                    family: Config.Theme.fontFamily
                                    pixelSize: Config.Theme.fontSizeSmall
                                }

                            }

                            Text {
                                text: Services.BluetoothControl.busyAddress === modelData.address
                                    ? (Services.BluetoothControl.busyAction === "pair" ? "Pairing…"
                                       : Services.BluetoothControl.busyAction === "trust" ? "Saving pairing…"
                                       : Services.BluetoothControl.busyAction === "connect" ? "Connecting…"
                                       : Services.BluetoothControl.busyAction === "disconnect" ? "Disconnecting…" : "Removing…")
                                    : (Services.BluetoothControl.isConnected(modelData.address) ? "Connected" : (modelData.paired ? "Paired" : "Available to pair"))
                                color: Services.BluetoothControl.isConnected(modelData.address) || Services.BluetoothControl.busyAddress === modelData.address
                                    ? Config.Theme.colHighlight : Config.Theme.colMuted

                                font {
                                    family: Config.Theme.fontFamily
                                    pixelSize: Config.Theme.fontSizeCaption
                                }

                            }

                            Text {
                                visible: Services.BluetoothControl.batteryLabel(modelData.address) !== ""
                                text: "Battery " + Services.BluetoothControl.batteryLabel(modelData.address)
                                color: Config.Theme.colMuted
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontSizeCaption
                            }

                        }

                        Text {
                            text: Services.BluetoothControl.busyAddress === modelData.address ? "sync"
                                : (Services.BluetoothControl.isConnected(modelData.address) ? "link_off" : "link")
                            color: Config.Theme.colMuted

                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: Config.Theme.iconSizeSm
                            }

                        }

                    }

                    MouseArea {
                        id: bluetoothDeviceMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Services.BluetoothControl.isConnected(modelData.address))
                                Services.BluetoothControl.disconnectDevice(modelData.address);
                            else if (modelData.paired)
                                Services.BluetoothControl.connectDevice(modelData.address);
                            else
                                Services.BluetoothControl.pairDevice(modelData.address);
                        }
                    }

                        Text {
                            id: bluetoothForgetIcon
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 30
                            text: "delete_outline"
                            visible: modelData.paired && (bluetoothDeviceDelegate.activeFocus
                                || bluetoothDeviceMouse.containsMouse || bluetoothForgetMouse.containsMouse
                                || activeFocus)
                            color: activeFocus || bluetoothForgetMouse.containsMouse
                                ? Config.Theme.colRed : Config.Theme.colMuted
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Config.Theme.iconSizeSm
                            z: 2
                            activeFocusOnTab: modelData.paired
                            Accessible.role: Accessible.Button
                            Accessible.name: "Forget Bluetooth device " + modelData.name
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                        || event.key === Qt.Key_Space) {
                                    Services.BluetoothControl.forgetDevice(modelData.address);
                                    event.accepted = true;
                                }
                            }

                            MouseArea {
                                id: bluetoothForgetMouse
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Services.BluetoothControl.forgetDevice(modelData.address)
                            }
                        }

                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: Services.BluetoothControl.pendingForgetAddress !== ""
                implicitHeight: visible ? forgetConfirmation.implicitHeight + 16 : 0
                radius: Config.Theme.radiusControl
                color: Config.Theme.alpha(Config.Theme.colRed, 0.14)

                ColumnLayout {
                    id: forgetConfirmation
                    anchors.fill: parent
                    anchors.margins: Config.Theme.spaceSm
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: "Forget “" + Services.BluetoothControl.deviceName(Services.BluetoothControl.pendingForgetAddress) + "”?"
                        color: Config.Theme.colFg
                        wrapMode: Text.Wrap
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeCaption
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Config.Theme.spaceSm
                        Item { Layout.fillWidth: true }

                        Text {
                            text: "Cancel"
                            color: Config.Theme.colMuted
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeCaption
                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: "Cancel removing Bluetooth device"
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                        || event.key === Qt.Key_Space) {
                                    Services.BluetoothControl.pendingForgetAddress = "";
                                    event.accepted = true;
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Services.BluetoothControl.pendingForgetAddress = ""
                            }
                        }

                        Text {
                            text: "Forget"
                            color: Config.Theme.colRed
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeCaption
                            font.bold: true
                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: "Confirm removing Bluetooth device"
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                        || event.key === Qt.Key_Space) {
                                    Services.BluetoothControl.confirmForget();
                                    event.accepted = true;
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Services.BluetoothControl.confirmForget()
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: Services.BluetoothControl.actionMessage !== ""
                text: Services.BluetoothControl.actionMessage
                color: Config.Theme.colRed
                wrapMode: Text.Wrap
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeCaption
            }

            // Bluetooth scan button
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: Config.Theme.radiusControl
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: Services.BluetoothControl.scanning ? "Stop Bluetooth scan" : "Scan for Bluetooth devices"
                color: activeFocus
                    ? Config.Theme.alpha(Config.Theme.colHighlight, Config.Theme.stateSelectedOpacity)
                    : (bluetoothScanMouse.containsMouse
                        ? Config.Theme.alpha(Config.Theme.colTextSec, Config.Theme.stateHoverOpacity)
                        : "transparent")
                border.width: activeFocus ? 1 : 0
                border.color: Config.Theme.colHighlight

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        if (Services.BluetoothControl.scanning)
                            Services.BluetoothControl.stopScan();
                        else
                            Services.BluetoothControl.startScan();
                        event.accepted = true;
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: Services.BluetoothControl.scanning ? "sync" : "bluetooth_searching"
                        color: Config.Theme.colHighlight

                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: Config.Theme.iconSizeSm
                        }

                    }

                    Text {
                        text: Services.BluetoothControl.scanning ? "Scanning..." : "Scan for devices"
                        color: Config.Theme.colFg

                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: Config.Theme.fontSizeCaption
                        }

                    }

                }

                MouseArea {
                    id: bluetoothScanMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Services.BluetoothControl.scanning)
                            Services.BluetoothControl.stopScan();
                        else
                            Services.BluetoothControl.startScan();
                    }
                }

            }

        }

    }

}
