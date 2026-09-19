pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Cores dinâmicas do Matugen (Colors.qml lê colors.json e observa alterações).
    // Os nomes antigos são preservados para não precisar alterar cada módulo.
    // Mantém os cantos visíveis enquanto o JSON do Matugen é recarregado.
    property color colBg: Colors.md3.surface === "transparent" ? "#13151A" : Colors.md3.surface
    property color colFg: Colors.md3.on_surface
    property color colText: Colors.md3.on_surface
    property color colTextSec: Colors.md3.on_surface_variant
    property color colMuted: Colors.md3.outline
    property color colDisabled: Colors.md3.outline_variant
    property color colHighlight: Colors.md3.primary
    property color colBlue: Colors.md3.secondary
    property color colYellow: Colors.md3.tertiary
    property color colRed: Colors.md3.error
    property color colOrange: Colors.md3.tertiary
    property color colGreen: Colors.md3.secondary
    property color colBatteryCritical: Colors.md3.error
    property color colBatteryIconDark: Colors.md3.surface_dim
    property color colBatteryIconLight: Colors.md3.on_surface
    property color colOsdBg: Colors.md3.surface_container_high
    property color colOsdMuted: Colors.md3.outline
    property color colOsdBorder: Colors.md3.outline_variant
    property color colWlogoutBg: Colors.md3.surface_dim
    property color colWlogoutButton: Colors.md3.surface_container
    property color colWlogoutButtonHover: Colors.md3.primary_container
    property color colWlogoutText: Colors.md3.on_surface
    property color colBorder: Colors.md3.outline

    // Fontes
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSizeSmall: 12
    property int fontSizeClock: 13
    property int fontSize: 14
    property int fontSizeLarge: 18

    // Barra e módulos
    property int barInset: 0
    property int barHeight: 36
    property int barRadius: 0
    property int barContentMargin: 8
    property int screenRadius: 16
    property int moduleHeight: 36
    property int moduleSpacing: 8
    property int moduleInnerSpacing: 4
    property int moduleTightSpacing: 3
    property int mediaMaxWidth: 350
    property int separatorWidth: 1
    property int separatorHeight: 16
    property int separatorRadius: 1

    // Grupos de módulos
    property int moduleGroupHeight: 28
    property int moduleGroupRadius: 10
    property real moduleGroupOpacity: 0.12


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
