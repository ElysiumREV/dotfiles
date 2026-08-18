import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".." as Config

PanelWindow {
    id: root

    required property date currentDate
    required property var positionProvider
    property date viewedMonth: new Date()
    property real enterProgress: 0
    property real popupX: 0

    color: "transparent"
    visible: false
    implicitWidth: 328
    implicitHeight: 370
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

    readonly property int firstDayOffset: {
        const firstDay = new Date(
            viewedMonth.getFullYear(), viewedMonth.getMonth(), 1
        ).getDay();
        return (firstDay + 6) % 7; // Calendário começa na segunda-feira.
    }
    readonly property int daysInViewedMonth: new Date(
        viewedMonth.getFullYear(), viewedMonth.getMonth() + 1, 0
    ).getDate()

    function openCalendar() {
        viewedMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
        popupX = positionProvider(implicitWidth).x;
        visible = true;
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
        duration: 180
        easing.type: Easing.OutCubic
    }

    Rectangle {
        anchors.fill: parent
        opacity: root.enterProgress
        transform: Translate { y: (1 - root.enterProgress) * -10 }
        color: Config.Theme.colBg
        radius: 12
        border.width: 1
        border.color: Qt.rgba(
            Config.Theme.colTextSec.r,
            Config.Theme.colTextSec.g,
            Config.Theme.colTextSec.b,
            0.25
        )

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "calendar_month"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 21
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
                    pixelSize: 30
                    bold: true
                }
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.rgba(
                    Config.Theme.colTextSec.r,
                    Config.Theme.colTextSec.g,
                    Config.Theme.colTextSec.b,
                    0.25
                )
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "chevron_left"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
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
                    font.pixelSize: 22
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
                    model: ["S", "T", "Q", "Q", "S", "S", "D"]

                    delegate: Text {
                        required property string modelData
                        width: (calendarGrid.width - calendarGrid.columnSpacing * 6) / 7
                        height: 20
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
                        height: 27

                        Rectangle {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
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
