import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets
import "../." as Config
import "../services" as Services

PanelWindow {
    id: root

    required property var targetScreen
    required property var positionProvider
    property real popupRight: 16

    readonly property var notificationService: Services.Notifications
    readonly property bool isOpen: notificationService.centerVisible
        && notificationService.centerMonitor === Hyprland.monitorFor(targetScreen)

    screen: targetScreen
    color: "transparent"
    visible: isOpen
    focusable: visible
    implicitWidth: 410
    implicitHeight: Math.min(centerContent.implicitHeight + 28,
                             (targetScreen?.height ?? 720) - Config.Theme.barHeight - 24)
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    margins {
        top: Config.Theme.barHeight + 8
        right: popupRight
    }

    onVisibleChanged: {
        if (visible) {
            const position = positionProvider(implicitWidth);
            popupRight = position?.right ?? 16;
            notificationService.markAllRead();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Config.Theme.colBg
        radius: 12
        border.width: 1
        border.color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                              Config.Theme.colTextSec.b, 0.25)

        ColumnLayout {
            id: centerContent
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "notifications"
                    color: Config.Theme.colHighlight
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                }

                Text {
                    Layout.fillWidth: true
                    text: "Notificações"
                    color: Config.Theme.colFg
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeLarge
                    font.bold: true
                }

                Text {
                    text: notificationService.doNotDisturb ? "notifications_off" : "notifications_active"
                    color: notificationService.doNotDisturb ? Config.Theme.colYellow : Config.Theme.colTextSec
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 19

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notificationService.doNotDisturb = !notificationService.doNotDisturb
                    }
                }

                Text {
                    text: "close"
                    color: closeMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colMuted
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 19

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -5
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notificationService.closeCenter()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: notificationService.doNotDisturb ? "Não Perturbe ativado" : "Avisos recentes"
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                }

                Text {
                    text: "Limpar tudo"
                    color: clearMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colMuted
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: 10

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        anchors.margins: -5
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notificationService.clearHistory()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                               Config.Theme.colTextSec.b, 0.2)
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: 300

                Text {
                    anchors.centerIn: parent
                    visible: notificationService.history.length === 0
                    text: "Nenhuma notificação recente"
                    color: Config.Theme.colMuted
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                }

                ScrollView {
                    anchors.fill: parent
                    visible: notificationService.history.length > 0
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        width: parent.width
                        spacing: 7

                        Repeater {
                            model: notificationService.history

                            delegate: Rectangle {
                                id: notificationCard
                                required property var modelData

                                Layout.fillWidth: true
                                implicitHeight: notificationCardContent.implicitHeight + 20
                                radius: 9
                                color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                               Config.Theme.colTextSec.b, 0.08)
                                border.width: modelData.urgency === NotificationUrgency.Critical ? 1 : 0
                                border.color: Config.Theme.colRed

                                RowLayout {
                                    id: notificationCardContent
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 9

                                    IconImage {
                                        Layout.alignment: Qt.AlignTop
                                        implicitSize: 23
                                        source: modelData.appIcon !== ""
                                            ? (modelData.appIcon.includes(":") || modelData.appIcon.includes("/")
                                               ? modelData.appIcon : "image://icon/" + modelData.appIcon) : ""
                                        asynchronous: true
                                        visible: status === Image.Ready
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Rectangle {
                                                Layout.preferredWidth: 6
                                                Layout.preferredHeight: 6
                                                radius: 3
                                                color: Config.Theme.colHighlight
                                                visible: modelData.unread
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.appName
                                                color: Config.Theme.colTextSec
                                                font.family: Config.Theme.fontFamily
                                                font.pixelSize: 9
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: new Date(modelData.timestamp).toLocaleTimeString(Qt.locale(), "HH:mm")
                                                color: Config.Theme.colMuted
                                                font.family: Config.Theme.fontFamily
                                                font.pixelSize: 9
                                            }

                                            Text {
                                                text: "close"
                                                color: dismissMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colMuted
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 16
                                                MouseArea {
                                                    id: dismissMouse
                                                    anchors.fill: parent
                                                    anchors.margins: -5
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: notificationService.dismiss(modelData.id)
                                                }
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: text !== ""
                                            text: modelData.summary
                                            color: Config.Theme.colFg
                                            font.family: Config.Theme.fontFamily
                                            font.pixelSize: Config.Theme.fontSizeSmall
                                            font.bold: true
                                            wrapMode: Text.Wrap
                                            textFormat: Text.PlainText
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: text !== ""
                                            text: modelData.body
                                            color: Config.Theme.colTextSec
                                            font.family: Config.Theme.fontFamily
                                            font.pixelSize: 10
                                            wrapMode: Text.Wrap
                                            textFormat: Text.PlainText
                                        }

                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 5
                                            visible: modelData.active && modelData.notification
                                                && modelData.notification.actions.length > 0

                                            Repeater {
                                                model: modelData.notification?.actions ?? []

                                                delegate: Rectangle {
                                                    required property var modelData
                                                    width: centerActionText.implicitWidth + 16
                                                    height: 25
                                                    radius: 6
                                                    color: centerActionMouse.containsMouse
                                                        ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                                                  Config.Theme.colHighlight.b, 0.2)
                                                        : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                                                  Config.Theme.colTextSec.b, 0.12)

                                                    Text {
                                                        id: centerActionText
                                                        anchors.centerIn: parent
                                                        text: modelData.text
                                                        color: Config.Theme.colFg
                                                        font.family: Config.Theme.fontFamily
                                                        font.pixelSize: 9
                                                    }

                                                    MouseArea {
                                                        id: centerActionMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: modelData.invoke()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }

        Item {
            anchors.fill: parent
            focus: root.visible
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    notificationService.closeCenter();
                    event.accepted = true;
                }
            }
        }
    }
}
