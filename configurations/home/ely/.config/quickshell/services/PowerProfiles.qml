pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property string activeProfile: "balanced"
  property var availableProfiles: ["balanced", "performance", "power-saver"]
  property bool isAvailable: false

  Component.onCompleted: {
    checkAvailability()
    updateActiveProfile()
  }

  function checkAvailability() {
    checkProc.running = true
  }

  Process {
    id: checkProc
    command: ["which", "powerprofilesctl"]
    onExited: code => {
      root.isAvailable = code === 0
      if (root.isAvailable) {
        console.log("⚡ [PowerProfiles] Service available")
        root.updateActiveProfile()
      }
    }
  }

  function updateActiveProfile() {
    if(!isAvailable) return
    getProc.running = true
  }

  Process {
    id: getProc
    command: ["powerprofilesctl", "get"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.activeProfile = text.trim()
        console.log ("⚡ [PowerProfiles] Active Profile:", root.activeProfile)
      }
    }
  }

  function setProfile(profile: string) {
    if (!isAvailable) return
    if (!availableProfiles.includes(profile)) return

    setProc.exec(["powerprofilesctl", "set", profile])
  }

  Process {
    id: setProc
    onExited: code => {
      if (code === 0) {
        root.updateActiveProfile()
      }
    }
  }

  function getProfileIcon(profile: string): string {
    switch(profile) {
      case "performance": return "󰓅"
      case "balanced": return "󰾅"
      case "power-saver": return "󰂎"
      default: return "󰚥"
    }
  }

  function getProfileLabel(profile: string): string {
    switch(profile) {
      case "performance": return "Performance"
      case "balanced": return "Balanced"
      case "power-saver": return "Power Saver"
      default: return profile
    }
  }

  Timer {
    interval: 5000
    running: root.isAvailable
    repeat: true
    onTriggered: root.updateActiveProfile()
  }
}
