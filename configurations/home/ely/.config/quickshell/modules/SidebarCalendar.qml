import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../." as Config
import "../widgets" as Widgets

Item {
    id: root

    property date today: new Date()
    property date viewedMonth: new Date(today.getFullYear(), today.getMonth(), 1)
    property bool active: false
    property bool collapsed: false
    property bool compact: false
    readonly property real bodyHeight: collapsed ? 0 : calendarBody.implicitHeight
    readonly property int firstDayOffset: new Date(
        viewedMonth.getFullYear(), viewedMonth.getMonth(), 1
    ).getDay()
    signal collapseToggled(bool collapsed)

    implicitHeight: calendarContent.implicitHeight + 20
    Behavior on implicitHeight {
        NumberAnimation {
            duration: Config.Theme.motionDefault
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.Theme.curveSpatialDefault
        }
    }

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.today = new Date()
    }

    Widgets.SurfaceCard {
        anchors.fill: parent

        ColumnLayout {
            id: calendarContent
            anchors.fill: parent
            anchors.margins: root.compact ? Config.Theme.spaceXs : Config.Theme.spaceSm
            spacing: root.compact ? 2 : Config.Theme.spaceXs

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Widgets.IconButton {
                    iconName: "expand_less"
                    iconSize: 20
                    buttonRadius: 8
                    iconRotation: root.collapsed ? 180 : 0
                    implicitWidth: 28
                    implicitHeight: 28
                    Accessible.name: root.collapsed ? "Mostrar calendário" : "Recolher calendário"
                    onClicked: root.collapseToggled(!root.collapsed)
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 28

                    Text {
                        anchors.fill: parent
                        text: root.viewedMonth.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSize
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        opacity: root.collapsed ? 0 : 1
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Config.Theme.motionFast
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Config.Theme.curveEffects
                            }
                        }
                    }

                    Text {
                        anchors.fill: parent
                        text: root.today.toLocaleDateString(Qt.locale(), "dd MMMM yyyy")
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        opacity: root.collapsed ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Config.Theme.motionFast
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Config.Theme.curveEffects
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 2
                    visible: !root.collapsed
                    opacity: root.collapsed ? 0 : 1
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Config.Theme.motionFast
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Theme.curveEffects
                        }
                    }

                    Widgets.IconButton {
                        iconName: "chevron_left"
                        iconSize: 19
                        buttonRadius: 8
                        implicitWidth: 28
                        implicitHeight: 28
                        Accessible.name: "Mês anterior"
                        onClicked: root.viewedMonth = new Date(
                            root.viewedMonth.getFullYear(), root.viewedMonth.getMonth() - 1, 1
                        )
                    }

                    Widgets.IconButton {
                        iconName: "chevron_right"
                        iconSize: 19
                        buttonRadius: 8
                        implicitWidth: 28
                        implicitHeight: 28
                        Accessible.name: "Próximo mês"
                        onClicked: root.viewedMonth = new Date(
                            root.viewedMonth.getFullYear(), root.viewedMonth.getMonth() + 1, 1
                        )
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.bodyHeight
                clip: true

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: Config.Theme.motionDefault
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Config.Theme.curveSpatialDefault
                    }
                }

                ColumnLayout {
                    id: calendarBody
                    width: parent.width
                    spacing: 6

                    Grid {
                        id: weekdays
                        Layout.fillWidth: true
                        columns: 7
                        columnSpacing: 2

                        Repeater {
                            model: ["Do", "2ª", "3ª", "4ª", "5ª", "6ª", "Sá"]

                            delegate: Text {
                                required property string modelData
                                width: (weekdays.width - weekdays.columnSpacing * 6) / 7
                            height: root.compact ? 15 : 18
                                text: modelData
                                color: Config.Theme.colMuted
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontSizeSmall
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Grid {
                        id: daysGrid
                        Layout.fillWidth: true
                        columns: 7
                        columnSpacing: 2
                        rowSpacing: 2

                        Repeater {
                            model: 42

                            delegate: Item {
                                required property int index
                                readonly property date cellDate: new Date(
                                    root.viewedMonth.getFullYear(), root.viewedMonth.getMonth(),
                                    index - root.firstDayOffset + 1
                                )
                                readonly property bool inViewedMonth:
                                    cellDate.getMonth() === root.viewedMonth.getMonth()
                                readonly property bool isToday:
                                    cellDate.getDate() === root.today.getDate()
                                    && cellDate.getMonth() === root.today.getMonth()
                                    && cellDate.getFullYear() === root.today.getFullYear()

                                width: (daysGrid.width - daysGrid.columnSpacing * 6) / 7
                                height: root.compact ? 23 : 27

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: root.compact ? 21 : 25
                                    height: root.compact ? 21 : 25
                                    radius: width / 2
                                    color: isToday ? Config.Theme.colHighlight : "transparent"
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: cellDate.getDate()
                                    color: isToday ? Config.Theme.colBg
                                        : (inViewedMonth ? Config.Theme.colFg : Config.Theme.colMuted)
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: Config.Theme.fontSizeSmall
                                    font.bold: isToday
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
