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

    // Fontes
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14
}
