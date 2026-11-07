pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower as UPowerService

// Power profiles through the native UPower/power-profiles-daemon API.
// Profile ids keep the powerprofilesctl names ("balanced", "performance", "power-saver").
Singleton {
  id: root

  readonly property bool isAvailable: true
  readonly property var availableProfiles: UPowerService.PowerProfiles.hasPerformanceProfile
    ? ["balanced", "performance", "power-saver"]
    : ["balanced", "power-saver"]
  readonly property string activeProfile: {
    switch (UPowerService.PowerProfiles.profile) {
      case UPowerService.PowerProfile.Performance: return "performance"
      case UPowerService.PowerProfile.PowerSaver: return "power-saver"
      default: return "balanced"
    }
  }

  function setProfile(profile) {
    if (!availableProfiles.includes(profile)) return

    switch (profile) {
      case "performance": UPowerService.PowerProfiles.profile = UPowerService.PowerProfile.Performance; break
      case "power-saver": UPowerService.PowerProfiles.profile = UPowerService.PowerProfile.PowerSaver; break
      default: UPowerService.PowerProfiles.profile = UPowerService.PowerProfile.Balanced
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
