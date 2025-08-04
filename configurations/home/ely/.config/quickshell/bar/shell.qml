import Quickshell
import QtQuick

PanelWindow {
  anchors {
    left: true
    top: true
    right: true
  }
  implicitHeight: 32

  Text {
    anchors.centerIn: parent
    text: "bar"
  }
}