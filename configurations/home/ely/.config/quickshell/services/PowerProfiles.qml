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
  }

  function checkAvailability() {
    checkProc.running = true
  }

  Process {
    id: checkProc
    command: ["which", "powerprofilesctl"]
    onExited: code => {
      root.isAvailable = code === 0
      if (root.isAvailable)
        root.updateActiveProfile()
    }
  }

  function updateActiveProfile() {
    if (!isAvailable || getProc.running) return
    getProc.running = true
  }

  Process {
    id: getProc
    command: ["powerprofilesctl", "get"]
    stdout: StdioCollector {
      onStreamFinished: {
        const profile = text.trim()
        if (root.availableProfiles.includes(profile))
          root.activeProfile = profile
      }
    }
    onExited: code => {
      if (code !== 0)
        root.isAvailable = false
    }
  }

  function setProfile(profile) {
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

  function getProfileIcon(profile) {
    switch(profile) {
      case "performance": return "speed"
      case "balanced": return "balance"
      case "power-saver": return "energy_savings_leaf"
      default: return "bolt"
    }
  }

  function getProfileLabel(profile) {
    switch(profile) {
      case "performance": return "Performance"
      case "balanced": return "Balanced"
      case "power-saver": return "Power Saver"
      default: return profile
    }
  }

}
