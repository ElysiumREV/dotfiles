import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".." as Config
import "../widgets" as Widgets
import "./PopupGeometry.js" as PopupGeometry

PanelWindow {
    id: root

    property date currentDate: new Date()
    required property var targetScreen
    required property var positionProvider
    property date viewedMonth: new Date()
    property real enterProgress: 0
    property real popupX: 0
    readonly property bool compactLayout: (targetScreen?.height ?? 720) < 600

    color: "transparent"
    visible: false
    focusable: visible
    screen: targetScreen
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitWidth: PopupGeometry.widthForScreen(targetScreen, 328, 24)
    implicitHeight: PopupGeometry.heightForScreen(
        targetScreen, compactLayout ? 310 : 370, Config.Theme.barHeight + 8, 16
    )
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
    }

    margins {
        top: Config.Theme.barHeight + 8
        left: root.popupX
    }

    Widgets.FocusDismissBehavior {
        window: root
        dismissAction: () => root.visible = false
    }

    contentItem {
        focus: root.visible
        Keys.onEscapePressed: root.visible = false
    }

    readonly property int firstDayOffset: {
        const firstDay = new Date(
            viewedMonth.getFullYear(), viewedMonth.getMonth(), 1
        ).getDay();
        return firstDay; // Calendar starts on Sunday.
    }
    readonly property int daysInViewedMonth: new Date(
        viewedMonth.getFullYear(), viewedMonth.getMonth() + 1, 0
    ).getDate()

    function openCalendar() {
        currentDate = new Date();
        viewedMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
        popupX = positionProvider(implicitWidth).x;
        visible = true;
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentDate = new Date()
    }

    function changeMonth(delta) {
        viewedMonth = new Date(
            viewedMonth.getFullYear(), viewedMonth.getMonth() + delta, 1
        );
    }

    onVisibleChanged: {
        if (visible)
            openAnimation.restart();
        else
            enterProgress = 0;
    }

    NumberAnimation {
        id: openAnimation
        target: root
        property: "enterProgress"
        from: 0
        to: 1
        duration: Config.Theme.motionEnter
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Config.Theme.curveEnter
    }

    Rectangle {
        anchors.fill: parent
        opacity: root.enterProgress
        transform: Translate { y: (1 - root.enterProgress) * -10 }
        color: Config.Theme.colBg
        radius: Config.Theme.radiusCard
        border.width: 1
        border.color: Config.Theme.alpha(Config.Theme.colTextSec, 0.25)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.compactLayout ? 12 : 16
            spacing: root.compactLayout ? 8 : 12

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "calendar_month"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Config.Theme.iconSizeMd
                    color: Config.Theme.colHighlight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.currentDate.toLocaleDateString(
                        Qt.locale(), "dddd, dd MMMM yyyy"
                    )
                    color: Config.Theme.colFg
                    font {
                        family: Config.Theme.fontFamily
                        pixelSize: Config.Theme.fontSize
                        bold: true
                    }
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.currentDate.toLocaleTimeString(Qt.locale(), "HH:mm:ss")
                color: Config.Theme.colFg
                font {
                    family: Config.Theme.fontFamily
                    pixelSize: root.compactLayout ? 24 : 30
                    bold: true
                }
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Config.Theme.alpha(Config.Theme.colTextSec, 0.25)
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "chevron_left"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Config.Theme.iconSizeLg
                    color: previousMonthMouse.containsMouse
                           ? Config.Theme.colHighlight : Config.Theme.colFg

                    MouseArea {
                        id: previousMonthMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.changeMonth(-1)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.viewedMonth.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    color: Config.Theme.colFg
                    font {
                        family: Config.Theme.fontFamily
                        pixelSize: Config.Theme.fontSize
                        bold: true
                    }
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    text: "chevron_right"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Config.Theme.iconSizeLg
                    color: nextMonthMouse.containsMouse
                           ? Config.Theme.colHighlight : Config.Theme.colFg

                    MouseArea {
                        id: nextMonthMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.changeMonth(1)
                    }
                }
            }

            Grid {
                id: calendarGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                columnSpacing: 2
                rowSpacing: 3

                Repeater {
                    model: ["D", "S", "T", "Q", "Q", "S", "S"]

                    delegate: Text {
                        required property string modelData
                        width: (calendarGrid.width - calendarGrid.columnSpacing * 6) / 7
                        height: root.compactLayout ? 16 : 20
                        text: modelData
                        color: Config.Theme.colMuted
                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: Config.Theme.fontSizeSmall
                            bold: true
                        }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Repeater {
                    model: 42

                    delegate: Item {
                        required property int index
                        readonly property int day: index - root.firstDayOffset + 1
                        readonly property bool validDay: day >= 1 && day <= root.daysInViewedMonth
                        readonly property bool isToday: validDay
                            && day === root.currentDate.getDate()
                            && root.viewedMonth.getMonth() === root.currentDate.getMonth()
                            && root.viewedMonth.getFullYear() === root.currentDate.getFullYear()

                        width: (calendarGrid.width - calendarGrid.columnSpacing * 6) / 7
                        height: root.compactLayout ? 22 : 27

                        Rectangle {
                            anchors.centerIn: parent
                            width: root.compactLayout ? 20 : 24
                            height: root.compactLayout ? 20 : 24
                            radius: width / 2
                            color: isToday ? Config.Theme.colHighlight : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: validDay ? day : ""
                            color: isToday ? Config.Theme.colBg : Config.Theme.colFg
                            font {
                                family: Config.Theme.fontFamily
                                pixelSize: Config.Theme.fontSizeSmall
                                bold: isToday
                            }
                        }
                    }
                }
            }
        }
    }
}
