import QtQuick
import ".." as Config

Item {
    id: root

    property string iconName: "circle"
    property real progress: 0
    property color ringColor: Config.Theme.colHighlight
    property color iconColor: Config.Theme.colFg
    property int iconSize: 16
    property int diameter: 20

    implicitWidth: diameter
    implicitHeight: diameter

    Canvas {
        id: ring
        anchors.fill: parent
        antialiasing: true
        Component.onCompleted: requestPaint()

        onPaint: {
            const context = getContext("2d");
            context.clearRect(0, 0, width, height);

            const center = width / 2;
            const radius = Math.max(1, (Math.min(width, height) - 3) / 2);
            const startAngle = -Math.PI / 2;
            const normalizedProgress = Math.max(0, Math.min(1, root.progress));

            context.beginPath();
            context.lineWidth = 2;
            context.strokeStyle = Config.Theme.colMuted.toString();
            context.arc(center, center, radius, 0, Math.PI * 2, false);
            context.stroke();

            if (normalizedProgress > 0) {
                context.beginPath();
                context.lineWidth = 2.2;
                context.lineCap = "round";
                context.strokeStyle = root.ringColor.toString();
                context.arc(center, center, radius, startAngle,
                    startAngle + Math.PI * 2 * normalizedProgress, false);
                context.stroke();
            }
        }

        Connections {
            target: root
            function onProgressChanged() { ring.requestPaint(); }
            function onRingColorChanged() { ring.requestPaint(); }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.iconName
        color: root.iconColor
        font.family: "Material Symbols Rounded"
        font.pixelSize: root.iconSize
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
}
