import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Widgets
import Quickshell.Wayland
import "../." as Config
import "../services" as Services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(
        screen => Hyprland.monitorFor(screen) === Hyprland.focusedMonitor
    ) ?? Quickshell.screens[0] ?? null

    PanelWindow {
        id: popupWindow

        screen: root.focusedScreen
        color: "transparent"
        visible: !Services.Notifications.doNotDisturb
            && Services.Notifications.popupNotifications.length > 0
        implicitWidth: 360
        implicitHeight: popupColumn.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            right: true
        }

        margins {
            top: Config.Theme.barHeight + 12
            right: 16
        }

        Column {
            id: popupColumn
            width: popupWindow.implicitWidth
            spacing: 8

            Repeater {
                model: Services.Notifications.doNotDisturb
                    ? [] : Services.Notifications.popupNotifications.slice(0, 5)

                delegate: Rectangle {
                    id: card
                    required property var modelData

                    width: popupColumn.width
                    implicitHeight: cardContent.implicitHeight + 24
                    radius: 12
                    color: Config.Theme.colBg
                    border.width: 1
                    border.color: modelData.urgency === NotificationUrgency.Critical
                        ? Config.Theme.colRed
                        : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                  Config.Theme.colTextSec.b, 0.25)

                    Timer {
                        interval: modelData.expireTimeout > 0
                            ? Math.max(1, Math.round(modelData.expireTimeout * 1000)) : 3000
                        running: popupWindow.visible
                        onTriggered: Services.Notifications.expirePopup(modelData.id)
                    }

                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 7

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 9

                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                radius: 8
                                color: Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                               Config.Theme.colHighlight.b, 0.14)

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: 19
                                    source: modelData.appIcon !== ""
                                        ? (modelData.appIcon.includes(":") || modelData.appIcon.includes("/")
                                           ? modelData.appIcon : "image://icon/" + modelData.appIcon) : ""
                                    asynchronous: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: modelData.appIcon === ""
                                    text: "notifications"
                                    color: Config.Theme.colHighlight
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 18
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.appName || "Notificação"
                                    color: Config.Theme.colTextSec
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.summary || ""
                                    visible: text !== ""
                                    color: Config.Theme.colFg
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: Config.Theme.fontSizeSmall
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: "close"
                                color: closeMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colMuted
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 17

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    anchors.margins: -5
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Services.Notifications.archiveFromPopup(modelData.id)
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: modelData.body !== ""
                            text: modelData.body
                            textFormat: Text.PlainText
                            color: Config.Theme.colTextSec
                            wrapMode: Text.Wrap
                            maximumLineCount: 5
                            elide: Text.ElideRight
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: visible ? 132 : 0
                            visible: modelData.image !== ""
                            radius: 8
                            clip: true
                            color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                           Config.Theme.colTextSec.b, 0.08)

                            Image {
                                anchors.fill: parent
                                source: modelData.image
                                sourceSize.width: 672
                                sourceSize.height: 264
                                asynchronous: true
                                cache: false
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: modelData.actions.length > 0

                            Repeater {
                                model: modelData.actions
                                delegate: Rectangle {
                                    required property var modelData
                                    width: actionText.implicitWidth + 18
                                    height: 27
                                    radius: 7
                                    color: actionMouse.containsMouse
                                        ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                                  Config.Theme.colHighlight.b, 0.22)
                                        : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                                  Config.Theme.colTextSec.b, 0.12)

                                    Text {
                                        id: actionText
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        color: Config.Theme.colFg
                                        font.family: Config.Theme.fontFamily
                                        font.pixelSize: 10
                                    }

                                    MouseArea {
                                        id: actionMouse
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
