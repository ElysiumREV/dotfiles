pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Cores compartilhadas pela interface, alimentadas pelo tema gerado pelo Matugen.
    property color colBg: Colors.md3.surface
    property color colFg: Colors.md3.on_surface
    property color colText: Colors.md3.on_surface
    property color colTextSec: Colors.md3.on_surface_variant
    property color colMuted: Colors.md3.outline
    property color colDisabled: Colors.md3.outline_variant
    property color colHighlight: Colors.md3.primary
    property color colOnHighlight: Colors.md3.on_primary
    property color colHighlightContainer: Colors.md3.primary_container
    property color colOnHighlightContainer: Colors.md3.on_primary_container
    property color colBlue: Colors.md3.secondary
    property color colYellow: Colors.md3.tertiary
    property color colRed: Colors.md3.error
    property color colGreen: Colors.md3.secondary
    property color colBatteryCritical: Colors.md3.error
    property color colOsdBg: Colors.md3.surface_container_high
    property color colOsdMuted: Colors.md3.outline
    property color colOsdBorder: Colors.md3.outline_variant
    property color colWlogoutBg: Colors.md3.surface_dim
    property color colWlogoutButton: Colors.md3.surface_container
    property color colWlogoutButtonHover: Colors.md3.primary_container
    property color colWlogoutText: Colors.md3.on_surface
    property color colBorder: Colors.md3.outline

    // Superfícies semânticas para manter a hierarquia visual entre painéis e cartões.
    property color colPanel: Colors.md3.surface_container_low
    property color colSurface: Colors.md3.surface_container
    property color colSurfaceRaised: Colors.md3.surface_container_high
    property color colBorderSubtle: Colors.md3.outline_variant

    // Fontes
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSizeSmall: 12
    property int fontSize: 14
    property int fontSizeLarge: 18

    // Escala compartilhada de espaçamento, cantos e estados interativos.
    property int spaceXs: 4
    property int spaceSm: 8
    property int spaceMd: 12
    property int spaceLg: 16
    property int radiusControl: 8
    property int radiusCard: 12
    property int radiusPanel: 16
    property real stateHoverOpacity: 0.10
    property real stateSelectedOpacity: 0.18

    // Movimento inspirado no end-4: efeitos curtos, deslocamentos com resposta
    // expressiva e entradas/saídas assimétricas. Componentes usam a mesma escala.
    readonly property int motionFast: 200
    readonly property int motionDefault: 350
    readonly property int motionEnter: 400
    readonly property int motionExit: 200
    readonly property int motionResize: 300
    readonly property int motionSlow: 500
    readonly property list<real> curveSpatialFast: [0.42, 1.67, 0.21, 0.90, 1, 1]
    readonly property list<real> curveSpatialDefault: [0.38, 1.21, 0.22, 1.00, 1, 1]
    readonly property list<real> curveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1]
    readonly property list<real> curveEnter: [0.05, 0.70, 0.10, 1.00, 1, 1]
    readonly property list<real> curveExit: [0.30, 0.00, 0.80, 0.15, 1, 1]

    // Compatibilidade para os componentes de movimento compartilhado.
    readonly property int durPopupIn: motionEnter
    readonly property int durPopupOut: motionExit

    // Barra e módulos
    property int barInset: 0
    property int barHeight: 40
    property int barCompactWidthThreshold: 1200
    property int barMinimalWidthThreshold: 1000
    property int barRadius: 0
    property int barContentMargin: 8
    property int screenRadius: 10
    property int moduleHeight: 40
    property int moduleSpacing: 8
    property int moduleInnerSpacing: 4
    property int moduleTightSpacing: 3
    property int mediaMaxWidth: 350
    property int separatorWidth: 1
    property int separatorHeight: 16
    property int separatorRadius: 1

    // Grupos de módulos
    property int moduleGroupHeight: 32
    property int moduleGroupRadius: 12

    // Bateria
    property int batteryTextSize: 11

    // Tray
    property int trayItemSize: 18
    property int trayHoverPadding: 8
    property int trayHoverRadius: 6
    property int trayIconSourceSize: 32

    // OSD
    property int osdWidth: 310
    property int osdHeight: 78
    property int osdSpacing: 12
    property int osdIconSize: 22
    property int osdBarHeight: 8
    property int osdBarRadius: 4
    property int osdBorderWidth: 1
    property int osdAnimationDuration: 180

    // Logout
    property real wlogoutGridScale: 0.75
    property real wlogoutIconScale: 0.25
    property int wlogoutTextSize: 20
    property int wlogoutBorderWidth: 1
}
