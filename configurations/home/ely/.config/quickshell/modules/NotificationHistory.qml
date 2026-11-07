import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../." as Config
import "../services" as Services
import "../widgets" as Widgets

Item {
    id: root

    readonly property var notificationService: Services.Notifications
    property bool panelActive: false
    property bool showHeader: true
    implicitWidth: 382
    implicitHeight: centerContent.implicitHeight
    focus: panelActive

    onPanelActiveChanged: {
        if (panelActive) {
            notificationService.markAllRead();
            Qt.callLater(() => historyList.forceActiveFocus());
        }
    }

    ColumnLayout {
        id: centerContent
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.showHeader

            Text {
                text: "notifications"
                color: Config.Theme.colHighlight
                font.family: "Material Symbols Rounded"
                font.pixelSize: 22
            }

            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: Config.Theme.colFg
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeLarge
                font.bold: true
            }

            Widgets.IconButton {
                Accessible.name: notificationService.doNotDisturb
                    ? "Turn off Do Not Disturb" : "Turn on Do Not Disturb"
                iconName: notificationService.doNotDisturb ? "notifications_off" : "notifications_active"
                selected: notificationService.doNotDisturb
                onClicked: notificationService.doNotDisturb = !notificationService.doNotDisturb
            }

            Widgets.IconButton {
                Accessible.name: "Close notification center"
                iconName: "close"
                onClicked: notificationService.closeCenter()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: notificationService.doNotDisturb ? "Do Not Disturb on" : "Recent alerts"
                color: Config.Theme.colTextSec
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
            }

            Widgets.LabelButton {
                visible: notificationService.history.length > 0
                Accessible.name: "Clear all notifications"
                text: "Clear all"
                labelFontSize: 10
                labelAlignment: Text.AlignRight
                idleTextColor: Config.Theme.colMuted
                hoverTextColor: Config.Theme.colHighlight
                hoverBackgroundColor: Qt.rgba(
                    Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                    Config.Theme.colHighlight.b, 0.12
                )
                cornerRadius: 6
                onClicked: notificationService.clearHistory()
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
            implicitHeight: notificationService.historyGroups.length > 0 ? 300 : 48

            Text {
                anchors.centerIn: parent
                visible: notificationService.historyGroups.length === 0
                text: "No recent notifications"
                color: Config.Theme.colMuted
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
            }

            ListView {
                id: historyList
                anchors.fill: parent
                visible: notificationService.historyGroups.length > 0
                clip: true
                spacing: Config.Theme.spaceSm
                boundsBehavior: Flickable.StopAtBounds
                activeFocusOnTab: true
                reuseItems: true
                model: notificationService.historyGroups
                add: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            properties: "opacity"
                            from: 0
                            to: 1
                            duration: Config.Theme.motionFast
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Theme.curveEnter
                        }
                        NumberAnimation {
                            properties: "scale"
                            from: 0.96
                            to: 1
                            duration: Config.Theme.motionDefault
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Theme.curveSpatialFast
                        }
                    }
                }
                remove: Transition {
                    NumberAnimation {
                        properties: "opacity"
                        to: 0
                        duration: Config.Theme.motionExit
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Config.Theme.curveExit
                    }
                }
                displaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: Config.Theme.motionFast
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Config.Theme.curveSpatialDefault
                    }
                }
                ScrollBar.vertical: Widgets.ThemeScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Item {
                    id: groupDelegate
                    required property var modelData
                    width: ListView.view.width
                    implicitHeight: groupColumn.implicitHeight
                    height: implicitHeight
                    property bool expanded: false
                    Behavior on implicitHeight {
                        NumberAnimation {
                            duration: Config.Theme.motionDefault
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Theme.curveSpatialDefault
                        }
                    }

                    Column {
                        id: groupColumn
                        width: parent.width
                        spacing: 4

                        Button {
                            id: groupButton
                            width: parent.width
                            implicitHeight: 30
                            Accessible.name: groupDelegate.modelData.appName + ", "
                                + groupDelegate.modelData.notifications.length + " notifications. "
                                + (groupDelegate.expanded ? "Collapse group" : "Expand group")
                            onClicked: groupDelegate.expanded = !groupDelegate.expanded

                            contentItem: RowLayout {
                                spacing: Config.Theme.spaceSm

                                IconImage {
                                    Layout.preferredWidth: 19
                                    Layout.preferredHeight: 19
                                    source: groupDelegate.modelData.appIcon !== ""
                                        ? (groupDelegate.modelData.appIcon.includes(":")
                                            || groupDelegate.modelData.appIcon.includes("/")
                                            ? groupDelegate.modelData.appIcon
                                            : "image://icon/" + groupDelegate.modelData.appIcon) : ""
                                    asynchronous: true
                                    visible: status === Image.Ready
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: groupDelegate.modelData.appName
                                    color: Config.Theme.colTextSec
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: groupDelegate.modelData.notifications.length > 1
                                        ? String(groupDelegate.modelData.notifications.length) : ""
                                    color: Config.Theme.colMuted
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 9
                                }

                                Text {
                                    text: groupDelegate.expanded ? "expand_less" : "expand_more"
                                    color: groupButton.activeFocus || groupButton.hovered
                                        ? Config.Theme.colHighlight : Config.Theme.colMuted
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 17
                                }
                            }
                            background: Rectangle {
                                radius: 7
                                color: groupButton.activeFocus || groupButton.hovered
                                    ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                              Config.Theme.colHighlight.b, 0.10) : "transparent"
                            }
                        }

                        Repeater {
                            model: groupDelegate.expanded
                                ? groupDelegate.modelData.notifications
                                : groupDelegate.modelData.notifications.slice(0, 1)

                            delegate: Widgets.SurfaceCard {
                                id: notificationCard
                                required property var modelData

                                width: groupColumn.width
                                implicitHeight: notificationCardContent.implicitHeight + 20
                                height: implicitHeight
                                surfaceColor: Config.Theme.colSurface
                                outlined: modelData.urgency === NotificationUrgency.Critical
                                outlineColor: Config.Theme.colRed

                                RowLayout {
                                    id: notificationCardContent
                                    anchors.fill: parent
                                    anchors.margins: Config.Theme.spaceSm
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
                                                font.pixelSize: Config.Theme.fontSizeSmall
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: new Date(modelData.timestamp).toLocaleTimeString(Qt.locale(), "HH:mm")
                                                color: Config.Theme.colMuted
                                                font.family: Config.Theme.fontFamily
                                                font.pixelSize: 9
                                            }

                                            Widgets.IconButton {
                                                iconName: "close"
                                                iconSize: 16
                                                buttonRadius: 6
                                                implicitWidth: 23
                                                implicitHeight: 23
                                                Accessible.name: "Dismiss notification from " + modelData.appName
                                                onClicked: notificationService.dismiss(modelData.id)
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: text !== ""
                                            text: modelData.summary
                                            color: Config.Theme.colFg
                                            font.family: Config.Theme.fontFamily
                                            font.pixelSize: Config.Theme.fontSize
                                            font.bold: true
                                            wrapMode: Text.Wrap
                                            textFormat: Text.PlainText
                                            maximumLineCount: groupDelegate.expanded ? 3 : 2
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: text !== ""
                                            text: modelData.body
                                            color: Config.Theme.colTextSec
                                            font.family: Config.Theme.fontFamily
                                            font.pixelSize: Config.Theme.fontSizeSmall
                                            wrapMode: Text.Wrap
                                            textFormat: Text.PlainText
                                            maximumLineCount: groupDelegate.expanded ? 5 : 2
                                            elide: Text.ElideRight
                                        }

                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 5
                                            visible: modelData.active && modelData.notification
                                                && modelData.notification.actions.length > 0

                                            Repeater {
                                                model: modelData.notification?.actions ?? []

                                                delegate: Widgets.LabelButton {
                                                    required property var modelData
                                                    text: modelData.text
                                                    Accessible.name: modelData.text
                                                    implicitHeight: 25
                                                    labelFontSize: 9
                                                    contentHorizontalPadding: 8
                                                    cornerRadius: 6
                                                    idleTextColor: Config.Theme.colFg
                                                    hoverTextColor: Config.Theme.colFg
                                                    idleBackgroundColor: Qt.rgba(
                                                        Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                                        Config.Theme.colTextSec.b, 0.12
                                                    )
                                                    hoverBackgroundColor: Qt.rgba(
                                                        Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                                        Config.Theme.colHighlight.b, 0.2
                                                    )
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

    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            notificationService.closeCenter();
            event.accepted = true;
        }
    }
}
