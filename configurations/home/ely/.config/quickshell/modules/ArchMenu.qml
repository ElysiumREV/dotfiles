import ".." as Config
import "../services" as Services
import "../widgets" as Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as QsModules
import "./archmenu" as ArchParts
import "./PopupGeometry.js" as PopupGeometry
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property var positionProvider
    property real popupRight: 16
    property real enterProgress: 0
    property string uptimeText: "Up …"
    property string activeTab: "notifications"
    readonly property bool compactLayout: (targetScreen?.height ?? 720) < 800
    readonly property bool compactWidth: implicitWidth < 360
    readonly property var pipewire: Services.Volume.pipewire
    readonly property var outputDevices: Services.Volume.outputDevices
    readonly property var inputDevices: Services.Volume.inputDevices
    readonly property var outputAppNodes: Services.Volume.outputAppNodes
    property int wifiInitialVisibleCount: 6
    readonly property int wifiMaxHeight: Math.max(72, Math.min(280, (screen?.height ?? 720) * 0.28))
    readonly property int bluetoothMaxHeight: Math.max(72, Math.min(200, (screen?.height ?? 720) * 0.22))

    function ensureItemVisible(flickable, itemY, itemHeight) {
        const maxContentY = Math.max(0, flickable.contentHeight - flickable.height);
        if (itemY < flickable.contentY)
            flickable.contentY = Math.max(0, itemY);
        else if (itemY + itemHeight > flickable.contentY + flickable.height)
            flickable.contentY = Math.min(maxContentY, itemY + itemHeight - flickable.height);
    }

    function revealNetworkRow(row, list) {
        ensureItemVisible(list, row.y, row.height);
        Qt.callLater(() => {
            const viewport = content.contentItem;
            const position = row.mapToItem(viewport, 0, 0);
            ensureItemVisible(viewport, position.y, row.height);
        });
    }

    function openMenu() {
        popupRight = positionProvider(implicitWidth).right ?? 16;
        // Opens on the main tab (like end-4's quick settings) unless a specific tab was requested.
        activeTab = Services.Notifications.centerRequestedTab || "notifications";
        Services.WifiControl.reset();
        Services.BluetoothControl.expanded = false;
        Services.BluetoothControl.refresh();
        uptimeProcess.exec(["cat", "/proc/uptime"]);
        visible = true;
    }

    Connections {
        target: Services.WifiControl
        function onPasswordRequested() {
            Qt.callLater(() => wifiPanel.focusPassword());
        }
    }

    Connections {
        target: Services.Notifications
        function onCenterRequestedTabChanged() {
            if (root.visible)
                root.activeTab = Services.Notifications.centerRequestedTab;
        }
    }

    function formatUptime(seconds) {
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        if (days > 0)
            return "Up " + days + "d " + hours + "h";
        if (hours > 0)
            return "Up " + hours + "h " + minutes + " min";
        return minutes > 0 ? "Up " + minutes + " min" : "Up less than 1 min";
    }

    function audioNodeName(node) {
        return node?.nickname || node?.description || node?.name || "Audio device";
    }

    function audioDeviceIndex(devices, preferredDevice, currentDevice) {
        const currentIndex = currentDevice ? devices.indexOf(currentDevice) : -1;
        if (currentIndex >= 0)
            return currentIndex;

        const preferredIndex = preferredDevice ? devices.indexOf(preferredDevice) : -1;
        return preferredIndex;
    }

    function audioAppName(node) {
        const properties = node?.properties ?? {};
        const application = properties["application.name"]
            || node?.description || node?.name || "Application";
        const media = properties["media.name"];
        return media && media !== application ? application + " · " + media : application;
    }

    function selectOutputDevice(index) {
        if (index >= 0 && index < outputDevices.length)
            pipewire.preferredDefaultAudioSink = outputDevices[index];
    }

    function selectInputDevice(index) {
        if (index >= 0 && index < inputDevices.length)
            pipewire.preferredDefaultAudioSource = inputDevices[index];
    }

    function toggleAppMute(node) {
        Services.Volume.toggleNodeMute(node);
    }

    function setAppVolume(node, value) {
        Services.Volume.setNodeVolume(node, value);
    }

    onVisibleChanged: {
        Services.BluetoothControl.menuVisible = visible;
        if (!visible) {
            enterProgress = 0;
            Services.Notifications.closeCenter();
            cleanupTransientActions();
        } else {
            openAnimation.restart();
            Qt.callLater(() => wifiPowerButton.forceActiveFocus());
        }
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

    onActiveTabChanged: {
        if (Services.Notifications.centerRequestedTab !== activeTab)
            Services.Notifications.centerRequestedTab = activeTab;
        Qt.callLater(() => {
            if (content.contentItem)
                content.contentItem.contentY = 0;
        });
    }

    Component.onDestruction: cleanupTransientActions()

    function cleanupTransientActions() {
        Services.WifiControl.cleanup();
        Services.BluetoothControl.cleanup();
    }

    color: "transparent"
    visible: false
    focusable: visible
    screen: targetScreen
    implicitWidth: PopupGeometry.widthForScreen(targetScreen, 420, 24)
    implicitHeight: Math.max(1,
        (targetScreen?.height ?? 720) - Config.Theme.barHeight - 24
    )
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
        bottom: true
    }

    margins {
        top: Config.Theme.barHeight + 8
        right: root.popupRight
        bottom: 8
    }

    Widgets.FocusDismissBehavior {
        window: root
        dismissAction: () => root.visible = false
    }

    contentItem {
        focus: root.visible
        Keys.onEscapePressed: root.visible = false
    }

    Process {
        id: uptimeProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const seconds = Number(text.trim().split(/\s+/)[0]);
                if (Number.isFinite(seconds) && seconds >= 0)
                    root.uptimeText = root.formatUptime(Math.floor(seconds));
            }
        }
    }

    Widgets.SurfaceCard {
        anchors.fill: parent
        opacity: root.enterProgress
        transform: Translate { y: (1 - root.enterProgress) * -10 }
        surfaceColor: Config.Theme.colPanel
        cornerRadius: Config.Theme.radiusPanel
        outlineOpacity: 0.72
    }

    ScrollView {
        id: content
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: sidebarCalendar.top
            topMargin: Config.Theme.spaceLg
            leftMargin: Config.Theme.spaceLg
            rightMargin: Config.Theme.spaceLg
            bottomMargin: Config.Theme.spaceSm
        }
        clip: true
        contentWidth: availableWidth
        ScrollBar.vertical: Widgets.ThemeScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: contentColumn
            width: content.availableWidth
            height: Math.max(content.height, implicitHeight)
            spacing: Config.Theme.spaceSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.Theme.spaceSm
            Text {
                text: "timer"
                color: Config.Theme.colHighlight
                font.family: "Material Symbols Rounded"
                font.pixelSize: Config.Theme.iconSizeMd
            }

            Text {
                Layout.fillWidth: true
                text: root.uptimeText
                color: Config.Theme.colFg
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSize
                font.bold: true
            }

            Widgets.IconButton {
                iconName: "close"
                implicitWidth: 34
                implicitHeight: 34
                Accessible.name: "Close panel"
                onClicked: Services.Notifications.closeCenter()
            }

            Widgets.IconButton {
                id: wlogoutButton
                iconName: "power_settings_new"
                iconSize: Config.Theme.iconSizeMd
                buttonRadius: 10
                prominent: true
                filled: true
                idleIconColor: Config.Theme.colFg
                implicitWidth: 38
                implicitHeight: 36
                Accessible.name: "Open session options"
                ToolTip.text: "Open wlogout"
                ToolTip.visible: hovered
                onClicked: {
                    Services.Notifications.closeCenter();
                    Services.WindowControl.toggleLogout();
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Config.Theme.alpha(Config.Theme.colTextSec, 0.25)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.Theme.spaceSm
            RowLayout {
                Layout.fillWidth: true
                spacing: Config.Theme.spaceSm
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.compactLayout ? 58 : 66
                Accessible.role: Accessible.Grouping

                Rectangle {
                    anchors.fill: parent
                    radius: Config.Theme.radiusCard
                    color: Services.WifiControl.enabled
                        ? Config.Theme.alpha(Config.Theme.colHighlight, 0.22)
                        : Config.Theme.alpha(Config.Theme.colTextSec, 0.12)
                    border.width: Services.WifiControl.enabled ? 1 : 0
                    border.color: Config.Theme.colHighlight
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Config.Theme.spaceSm
                    spacing: 5

                    Text {
                        text: Services.WifiControl.enabled ? "wifi" : "wifi_off"
                        color: Services.WifiControl.enabled ? Config.Theme.colHighlight : Config.Theme.colMuted
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Config.Theme.iconSizeSm
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.fillWidth: true
                            text: "Wi-Fi"
                            color: Config.Theme.colFg
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: root.compactWidth ? Config.Theme.fontSizeCaption : Config.Theme.fontSizeSmall
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: Services.WifiControl.enabled ? Services.WifiControl.name
                                : (Services.WifiControl.hardwareEnabled ? "Disabled" : "Blocked")
                            color: Config.Theme.colTextSec
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeCaption
                            elide: Text.ElideRight
                        }
                    }

                    Widgets.IconButton {
                        id: wifiPowerButton
                        iconName: "power_settings_new"
                        selected: Services.WifiControl.enabled
                        implicitWidth: Config.Theme.controlMinSize
                        implicitHeight: 34
                        Accessible.name: Services.WifiControl.enabled ? "Turn off Wi-Fi" : "Turn on Wi-Fi"
                        onClicked: Services.WifiControl.toggle()
                    }
                    Widgets.IconButton {
                        implicitWidth: Config.Theme.controlMinSize
                        implicitHeight: 34
                        id: wifiDetailsButton
                        iconName: Services.WifiControl.expanded ? "expand_less" : "chevron_right"
                        Accessible.name: Services.WifiControl.expanded ? "Hide Wi-Fi networks" : "Show Wi-Fi networks"
                        onClicked: Services.WifiControl.toggleDetails()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.compactLayout ? 58 : 66
                Accessible.role: Accessible.Grouping

                Rectangle {
                    anchors.fill: parent
                    radius: Config.Theme.radiusCard
                    color: Services.BluetoothControl.enabled
                        ? Config.Theme.alpha(Config.Theme.colHighlight, 0.22)
                        : Config.Theme.alpha(Config.Theme.colTextSec, 0.12)
                    border.width: Services.BluetoothControl.enabled ? 1 : 0
                    border.color: Config.Theme.colHighlight
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Config.Theme.spaceSm
                    spacing: 5
                    Text {
                        text: "bluetooth"
                        color: Services.BluetoothControl.enabled ? Config.Theme.colHighlight : Config.Theme.colMuted
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Config.Theme.iconSizeSm
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.fillWidth: true
                            text: "Bluetooth"
                            color: Config.Theme.colFg
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: root.compactWidth ? Config.Theme.fontSizeCaption : Config.Theme.fontSizeSmall
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: Services.BluetoothControl.enabled
                                ? (Services.BluetoothControl.connected.length > 0 ? "Connected" : "On")
                                : "Disabled"
                            color: Config.Theme.colTextSec
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeCaption
                            elide: Text.ElideRight
                        }
                    }
                    Widgets.IconButton {
                        id: bluetoothPowerButton
                        iconName: "power_settings_new"
                        selected: Services.BluetoothControl.enabled
                        implicitWidth: Config.Theme.controlMinSize
                        implicitHeight: 34
                        Accessible.name: Services.BluetoothControl.enabled ? "Turn off Bluetooth" : "Turn on Bluetooth"
                        onClicked: Services.BluetoothControl.toggle()
                    }
                    Widgets.IconButton {
                        id: bluetoothDetailsButton
                        implicitWidth: Config.Theme.controlMinSize
                        implicitHeight: 34
                        iconName: Services.BluetoothControl.expanded ? "expand_less" : "chevron_right"
                        Accessible.name: Services.BluetoothControl.expanded ? "Hide Bluetooth devices" : "Show Bluetooth devices"
                        onClicked: Services.BluetoothControl.toggleDetails()
                    }
                }
            }

            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: Services.Brightness.supported
                spacing: Config.Theme.spaceXs
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "brightness_6"
                        color: Config.Theme.colHighlight

                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: Config.Theme.iconSizeMd
                        }

                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Brightness"
                        color: Config.Theme.colFg

                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: Config.Theme.fontSize
                            bold: true
                        }

                    }

                    Text {
                        text: Services.Brightness.percentage + "%"
                        color: Config.Theme.colMuted

                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: Config.Theme.fontSizeSmall
                        }

                    }

                }

                Item {
                    id: brightnessControl
                    Layout.fillWidth: true
                    implicitHeight: 16
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Slider
                    Accessible.name: "Screen brightness"

                    Keys.onPressed: event => {
                        const current = Services.Brightness.brightness;
                        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down)
                            Services.Brightness.setBrightness(Math.max(0, current - 0.05));
                        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up)
                            Services.Brightness.setBrightness(Math.min(1, current + 0.05));
                        else if (event.key === Qt.Key_Home)
                            Services.Brightness.setBrightness(0);
                        else if (event.key === Qt.Key_End)
                            Services.Brightness.setBrightness(1);
                        else
                            return;
                        event.accepted = true;
                    }

                    Rectangle {
                        id: brightnessTrack

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Config.Theme.alpha(Config.Theme.colTextSec, 0.2)

                        Rectangle {
                            width: parent.width * Services.Brightness.brightness
                            height: parent.height
                            radius: parent.radius
                            color: Config.Theme.colHighlight
                        }

                    }

                    Rectangle {
                        x: brightnessTrack.width * Services.Brightness.brightness - width / 2
                        anchors.verticalCenter: brightnessTrack.verticalCenter
                        width: 14
                        height: 14
                        radius: Config.Theme.radiusControl
                        color: Config.Theme.colFg
                        border.width: brightnessControl.activeFocus ? 2 : 0
                        border.color: Config.Theme.colHighlight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (mouse) => {
                            return Services.Brightness.setBrightness(mouse.x / width);
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed)
                                Services.Brightness.setBrightness(mouse.x / width);

                        }
                    }

                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Config.Theme.spaceSm
                visible: Services.Volume.captureApplications.length > 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.compactLayout ? 50 : 58
                visible: Services.Volume.captureApplications.length > 0
                Accessible.role: Accessible.Button
                Accessible.name: Services.Volume.microphoneMuted ? "Unmute microphone" : "Mute microphone"
                activeFocusOnTab: visible

                Rectangle {
                    anchors.fill: parent
                    radius: Config.Theme.radiusCard
                    color: micTileMouse.containsMouse || parent.activeFocus
                        ? Config.Theme.alpha(Config.Theme.colRed, 0.18)
                        : Config.Theme.alpha(Config.Theme.colTextSec, 0.12)
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Config.Theme.spaceSm
                    Text {
                        text: Services.Volume.microphoneMuted ? "mic_off" : "mic"
                        color: Services.Volume.microphoneMuted ? Config.Theme.colTextSec : Config.Theme.colRed
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Config.Theme.iconSizeSm
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Services.Volume.captureApplications.join(", ")
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeCaption
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: micTileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Volume.toggleMicrophoneMute()
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        Services.Volume.toggleMicrophoneMute();
                        event.accepted = true;
                    }
                }
            }

            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: Services.Media.connected
            implicitHeight: root.compactLayout ? 66 : 78
            radius: Config.Theme.radiusCard
            color: Config.Theme.alpha(Config.Theme.colTextSec, 0.12)

            RowLayout {
                anchors.fill: parent
                anchors.margins: root.compactLayout ? 8 : 10
                spacing: root.compactLayout ? 6 : 10

                Rectangle {
                    Layout.preferredWidth: root.compactLayout ? 44 : 52
                    Layout.preferredHeight: root.compactLayout ? 44 : 52
                    radius: Config.Theme.radiusControl
                    color: Config.Theme.alpha(Config.Theme.colTextSec, 0.18)
                    Text {
                        anchors.centerIn: parent
                        text: "music_note"
                        color: Config.Theme.colTextSec
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Config.Theme.iconSizeLg
                    }
                    Image {
                        anchors.fill: parent
                        source: Services.Media.artUrl
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        sourceSize.width: 104
                        sourceSize.height: 104
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: Services.Media.displayTitle
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Services.Media.displayArtist
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeCaption
                        elide: Text.ElideRight
                    }
                    Text {
                        text: Services.Media.displayName
                        color: Config.Theme.colMuted
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeCaption
                    }
                }

                Widgets.IconButton {
                    id: previousTrackButton
                    iconName: "skip_previous"
                    iconSize: Config.Theme.iconSizeMd
                    buttonRadius: 8
                    idleIconColor: Config.Theme.colFg
                    implicitWidth: Config.Theme.controlMinSize
                    implicitHeight: 34
                    Accessible.name: "Previous track"
                    enabled: Services.Media.canPrevious
                    onClicked: Services.Media.previous()
                }
                Widgets.IconButton {
                    id: toggleTrackButton
                    iconName: Services.Media.playing ? "pause" : "play_arrow"
                    iconSize: Config.Theme.iconSizeLg
                    buttonRadius: 10
                    prominent: true
                    filled: true
                    idleIconColor: Config.Theme.colFg
                    implicitWidth: 34
                    implicitHeight: 34
                    Accessible.name: Services.Media.playing ? "Pause" : "Resume playback"
                    enabled: Services.Media.canToggle
                    onClicked: Services.Media.togglePlayPause()
                }
                Widgets.IconButton {
                    id: nextTrackButton
                    iconName: "skip_next"
                    iconSize: Config.Theme.iconSizeMd
                    buttonRadius: 8
                    idleIconColor: Config.Theme.colFg
                    implicitWidth: Config.Theme.controlMinSize
                    implicitHeight: 34
                    Accessible.name: "Next track"
                    enabled: Services.Media.canNext
                    onClicked: Services.Media.next()
                }
            }
        }

        ArchParts.WifiPanel {
            id: wifiPanel
            menu: root
        }

        ArchParts.BluetoothPanel {
            id: bluetoothPanel
            menu: root
        }



        RowLayout {
            Layout.fillWidth: true
            spacing: Config.Theme.spaceXs
            Widgets.SegmentedTabButton {
                Layout.fillWidth: true
                Accessible.name: "Notifications"
                text: root.compactWidth ? "" : "Alerts"
                iconName: "notifications"
                selected: root.activeTab === "notifications"
                ToolTip.text: "Alerts"
                ToolTip.visible: root.compactWidth && hovered
                onClicked: root.activeTab = "notifications"
            }

            Widgets.SegmentedTabButton {
                Layout.fillWidth: true
                Accessible.name: "Volume mixer"
                text: root.compactWidth ? "" : "Mixer"
                iconName: "volume_up"
                selected: root.activeTab === "volume"
                ToolTip.text: "Mixer"
                ToolTip.visible: root.compactWidth && hovered
                onClicked: root.activeTab = "volume"
            }

            Widgets.SegmentedTabButton {
                Layout.fillWidth: true
                Accessible.name: "Battery info and power profile"
                text: root.compactWidth ? "" : "Battery"
                iconName: "battery_full"
                selected: root.activeTab === "battery"
                ToolTip.text: "Battery"
                ToolTip.visible: root.compactWidth && hovered
                onClicked: root.activeTab = "battery"
            }

            Widgets.SegmentedTabButton {
                Layout.fillWidth: true
                Accessible.name: "Quick shortcuts"
                text: root.compactWidth ? "" : "Shortcuts"
                iconName: "bolt"
                selected: root.activeTab === "shortcuts"
                ToolTip.text: "Shortcuts"
                ToolTip.visible: root.compactWidth && hovered
                onClicked: root.activeTab = "shortcuts"
            }

            Widgets.IconButton {
                Accessible.name: "Quickshell settings"
                iconName: "settings"
                selected: root.activeTab === "settings"
                ToolTip.text: Accessible.name
                ToolTip.visible: hovered
                onClicked: root.activeTab = "settings"
            }

            Widgets.IconButton {
                Accessible.name: Services.Notifications.doNotDisturb
                    ? "Turn off Do Not Disturb" : "Turn on Do Not Disturb"
                iconName: Services.Notifications.doNotDisturb ? "notifications_off" : "notifications_active"
                selected: Services.Notifications.doNotDisturb
                selectedIconColor: Config.Theme.colYellow
                ToolTip.text: Accessible.name
                ToolTip.visible: hovered
                onClicked: Services.Notifications.doNotDisturb = !Services.Notifications.doNotDisturb
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.activeTab === "volume" ? 1
                : root.activeTab === "battery" ? 2
                : root.activeTab === "shortcuts" ? 3
                : root.activeTab === "settings" ? 4 : 0

        NotificationHistory {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 280
            showHeader: false
            panelActive: root.visible && root.activeTab === "notifications"
        }

        ArchParts.MixerPage {
            menu: root
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.activeTab === "battery"
            sourceComponent: Component {
                QsModules.BatteryDetails {
                    width: content.availableWidth
                }
            }
        }

        ArchParts.ShortcutsPage {
            menu: root
        }

        ArchParts.SettingsPage {
            menu: root
        }

        }

        }
    }

    SidebarCalendar {
        id: sidebarCalendar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Config.Theme.spaceLg
            rightMargin: Config.Theme.spaceLg
            bottomMargin: Config.Theme.spaceLg
        }
        height: implicitHeight
        z: 1
        active: root.visible
        compact: root.compactLayout
        collapsed: Services.Notifications.centerCalendarCollapsed
        onCollapseToggled: collapsed => Services.Notifications.centerCalendarCollapsed = collapsed
    }

}
