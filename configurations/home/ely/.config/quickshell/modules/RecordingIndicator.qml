import QtQuick
import ".." as Config
import "../services" as QsServices

// Shown in the bar only while a screen recording is running; click to stop it.
Item {
    id: root

    property bool groupHighlighted: false

    readonly property var recorder: QsServices.ScreenRecorder
    readonly property bool isHovered: mouseArea.containsMouse || root.activeFocus

    implicitWidth: row.implicitWidth
    implicitHeight: Config.Theme.moduleHeight
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: "Stop screen recording, " + recorder.elapsedText

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            recorder.stop();
            event.accepted = true;
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.Theme.spaceXs + 2

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: width / 2
            color: Config.Theme.colRed

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.visible && root.recorder.recording
                NumberAnimation { to: 0.35; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.recorder.elapsedText
            color: root.groupHighlighted ? Config.Theme.colOnHighlightContainer : Config.Theme.colFg
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            font.bold: root.isHovered
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.recorder.stop()
    }
}
