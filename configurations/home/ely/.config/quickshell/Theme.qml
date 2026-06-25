pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Cores da barra
    property color colBg: "#13151A"
    property color colFg: "#d4c5b0"
    property color colText: "#F0F1F5"
    property color colTextSec: "#B8BCCA"
    property color colMuted: "#7C8291"
    property color colDisabled: "#505563"
    property color colHighlight: "#A08EC4"
    property color colBlue: "#7EA3CC"
    property color colYellow: "#e6c97a"
    property color colRed: "#C47A7A"
    property color colOrange: "#C4956A"
    property color colGreen: "#7EBD9B"
    property color colBatteryCritical: "#c0392b"
    property color colBatteryIconDark: "#181616"
    property color colBatteryIconLight: "#c5c9c5"
    property color colOsdBg: "#cc181616"
    property color colOsdMuted: "#2a1a1a"
    property color colOsdBorder: "#50c5c9c5"
    property color colWlogoutBg: "#e60c0c0c"
    property color colWlogoutButton: "#1e1e1e"
    property color colWlogoutButtonHover: "#3700b3"
    property color colWlogoutText: "white"
    property color colBorder: "black"

    // Fontes
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSizeSmall: 12
    property int fontSizeClock: 13
    property int fontSize: 14
    property int fontSizeLarge: 18

    // Barra e módulos
    property int barInset: 6
    property int barHeight: 30
    property int barRadius: 10
    property int barContentMargin: 8
    property int moduleHeight: 30
    property int moduleSpacing: 8
    property int moduleInnerSpacing: 4
    property int moduleTightSpacing: 3
    property int mediaMaxWidth: 350
    property int separatorWidth: 1
    property int separatorHeight: 16
    property int separatorRadius: 1

    // Bateria
    property int batteryTextSize: 11
    property int batteryIconSize: 10
    property int batteryShellWidth: 22
    property int batteryShellHeight: 14
    property int batteryBodyWidth: 16
    property int batteryBodyHeight: 10
    property real batteryBodyRadius: 2
    property real batteryBorderWidth: 1.5
    property real batteryFillMargin: 2.5
    property real batteryFillRadius: 1.5
    property int batteryTipWidth: 3
    property int batteryTipHeight: 5
    property real batteryTipRadius: 1.5
    property int batteryTipOverlap: -1

    // Tray
    property int trayItemSize: 18
    property int trayHoverPadding: 8
    property int trayHoverRadius: 6
    property int trayIconSourceSize: 32

    // OSD
    property int osdWidth: 200
    property int osdHeight: 50
    property int osdLeftMargin: 15
    property int osdRightMargin: 20
    property int osdSpacing: 10
    property int osdIconSize: 18
    property int osdBarHeight: 10
    property int osdBarRadius: 20
    property int osdBorderWidth: 1
    property int osdAnimationDuration: 150

    // Logout
    property real wlogoutGridScale: 0.75
    property real wlogoutIconScale: 0.25
    property int wlogoutTextTopMargin: 20
    property int wlogoutTextSize: 20
    property int wlogoutBorderWidth: 1
}
