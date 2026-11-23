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

    readonly property bool viewingCurrentMonth: viewedMonth.getFullYear() === today.getFullYear()
        && viewedMonth.getMonth() === today.getMonth()

    function changeMonth(offset) {
        viewedMonth = new Date(viewedMonth.getFullYear(), viewedMonth.getMonth() + offset, 1);
    }

    function showToday() {
        today = new Date();
        viewedMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    }

    implicitHeight: calendarContent.implicitHeight + 20
    Behavior on implicitHeight {
        NumberAnimation {
            duration: Config.Theme.motionDefault
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.Theme.curveSpatialDefault
        }
    }

    // "today" only changes at midnight: refresh on open and right after midnight,
    // instead of every second (each change re-evaluates the 42 day cells).
    function msUntilMidnight() {
        const now = new Date();
        const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
        return midnight.getTime() - now.getTime() + 500;
    }

    onActiveChanged: {
        if (active) {
            today = new Date();
            midnightTimer.interval = msUntilMidnight();
            midnightTimer.restart();
        } else {
            midnightTimer.stop();
        }
    }

    Timer {
        id: midnightTimer
        repeat: false
        onTriggered: {
            root.today = new Date();
            interval = root.msUntilMidnight();
            restart();
        }
    }

    Widgets.WheelAccumulator { id: wheelSteps }

    // Wheel over the calendar changes the month (down = next), like end-4's.
    WheelHandler {
        enabled: !root.collapsed
        onWheel: event => {
            const steps = wheelSteps.feed(event.angleDelta.y);
            if (steps !== 0)
                root.changeMonth(-steps);
        }
    }

    // Page Up/Down work while focus is anywhere in the calendar (e.g. its buttons).
    Keys.onPressed: event => {
        if (root.collapsed)
            return;
        if (event.key === Qt.Key_PageUp) {
            root.changeMonth(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_PageDown) {
            root.changeMonth(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Home) {
            root.showToday();
            event.accepted = true;
        }
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
                    iconSize: Config.Theme.iconSizeMd
                    buttonRadius: 8
                    iconRotation: root.collapsed ? 180 : 0
                    implicitWidth: Config.Theme.controlMinSize
                    implicitHeight: Config.Theme.controlMinSize
                    Accessible.name: root.collapsed ? "Show calendar" : "Collapse calendar"
                    onClicked: root.collapseToggled(!root.collapsed)
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 28

                    Text {
                        anchors.fill: parent
                        // "•" marks that another month is shown; clicking returns to today.
                        text: root.viewedMonth.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                            + (root.viewingCurrentMonth ? "" : "  •")
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

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.collapsed && !root.viewingCurrentMonth
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.showToday()
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
                        iconSize: Config.Theme.iconSizeSm
                        buttonRadius: 8
                        implicitWidth: Config.Theme.controlMinSize
                        implicitHeight: Config.Theme.controlMinSize
                        Accessible.name: "Previous month"
                        onClicked: root.changeMonth(-1)
                    }

                    Widgets.IconButton {
                        iconName: "chevron_right"
                        iconSize: Config.Theme.iconSizeSm
                        buttonRadius: 8
                        implicitWidth: Config.Theme.controlMinSize
                        implicitHeight: Config.Theme.controlMinSize
                        Accessible.name: "Next month"
                        onClicked: root.changeMonth(1)
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
                            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

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
