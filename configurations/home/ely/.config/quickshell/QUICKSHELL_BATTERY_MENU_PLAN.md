# Quickshell Battery Menu Implementation Plan

## Overview
This project modifies the Quickshell status bar to:
1. Remove the Power Profiles section from the ArchMenu
2. Create a new BatteryMenu popup that appears when clicking the battery
3. Display battery information: capacity (Wh), charge rate (W), status (charging/discharging), and charge cycles
4. Show the Power Profiles options below the battery info

## Files Modified

### 1. `modules/BatteryMenu.qml` (NEW)
A PanelWindow overlay component that displays:
- **Battery info section** (top):
  - Battery percentage large text
  - Capacity in Wh (energyCapacity)
  - Charge rate in Watts (changeRate: positive when charging, negative when discharging)
  - Status label (Carregando/Descarregando/Carregado)
- **Charge cycles** (obtained via `busctl --system get-property org.freedesktop.UPower /org/freedesktop/UPower/devices/battery_<nativePath> org.freedesktop.UPower.Device ChargeCycles`)
- **Power Profiles section** (below): identical to the one removed from ArchMenu, with 3 options (Performance/Balanced/Power Saver)
- Opens via `openMenu()` with `positionProvider` function
- Refreshes every 5 seconds when visible

### 2. `modules/Battery.qml` (MODIFIED)
- Added `signal requestMenu()` at item level
- Added `MouseArea` covering the entire item that emits `requestMenu()` on click
- This enables the battery click to open the BatteryMenu

### 3. `modules/ArchMenu.qml` (MODIFIED)
- **Removed** the Power Profiles block (lines 369-433): the `ColumnLayout` containing the `visible: Services.PowerProfiles.isAvailable` section with the 3 profile options and repeater delegate
- The remaining ArchMenu structure (wifi, bluetooth, brightness slider, logout options) is preserved

### 4. `modules/Bar.qml` (MODIFIED)
- Added `id: batteryItem` to the `QsModules.Battery` component
- Added `onRequestMenu: batteryMenu.openMenu()` handler to the Battery component
- Added `QsModules.BatteryMenu { id: batteryMenu; positionProvider: ... }` component instance
- The positionProvider maps from the battery item's position to determine where the menu appears
- The battery module now signals requestMenu when clicked, which opens the BatteryMenu

## Key Technical Details

### Battery Info Data Sources (from Quickshell UPower)
- `energyCapacity` → capacity in Wh (e.g., "38 Wh")
- `changeRate` → charge/discharge rate in Watts (positive = charging, negative = discharging)
- `state` (UPowerDeviceState enum) → status: Charging, Discharging, FullyCharged, Empty, etc.
- `percentage` → current charge level (0-100%)

### Charge Cycles Acquisition
- Quickshell does NOT expose `chargeCycles` property natively
- Obtained via D-Bus command: `busctl --system get-property org.freedesktop.UPower /org/freedesktop/UPower/devices/battery_<nativePath> org.freedesktop.UPower.Device ChargeCycles`
- The `nativePath` is available from `UPower.displayDevice.nativePath` (e.g., "BAT0")
- Path constructed as: `/org/freedesktop/UPower/devices/battery_${nativePath}`

### Power Profiles
- Uses existing `Services.PowerProfiles` singleton (from `services/PowerProfiles.qml`)
- Available profiles: ["balanced", "performance", "power-saver"]
- Active profile updated every 5 seconds when menu is visible

## UI Structure

### BatteryMenu.qml Layout
```
PanelWindow (overlay)
  ├── Rectangle (bg with border)
  │   └── ColumnLayout (content)
  │       ├── Row with battery icon + "Bateria" text + close button
  │       ├── Large percentage text + status label
  │       ├── Row: "battery_full_alt" + "Capacidade" + Wh value
  │       ├── Row: "bolt" + "Taxa de energia" + W value
  │       ├── Row: "loop" + "Ciclos de carga" + number or "—"
  │       ├── Separator
  │       ├── Row: "power" + "Perfil de energia" (header)
  │       ├── Row with 3 profile options (Repeater)
  │       └── Separator
  └── Action rows (lock/logout/reboot/shutdown) — PRESERVED FROM ARCHMENU
```

## Changes Summary

| File | Change |
|------|--------|
| `modules/BatteryMenu.qml` | Created new BatteryMenu PanelWindow component |
| `modules/Battery.qml` | Added `signal requestMenu()` + MouseArea for click |
| `modules/ArchMenu.qml` | Removed Power Profiles ColumnLayout (lines 369-433) |
| `modules/Bar.qml` | Connected battery click → BatteryMenu; added BatteryMenu instance |

## Remaining / Known Issues
- The `Bar.qml` file has some indentation/brace consistency issues that need review (the edit operations may have introduced formatting problems)
- The `BatteryMenu.qml` uses `busctl` command in a `Process` to get charge cycles — this requires `busctl` to be available in the environment
- The positionProvider logic maps battery position; actual positioning may need adjustment based on screen layout
- The Power Profiles section removed from ArchMenu is now only in BatteryMenu; if users also want it elsewhere, additional changes needed

## How to Use
1. The battery in the bar now opens the new BatteryMenu on click (instead of doing nothing)
2. The menu shows: percentage, capacity Wh, charge rate W, status, charge cycles, and 3 power profile options
3. Clicking the battery toggles the menu visibility
4. The menu auto-refreshes every 5 seconds to update data