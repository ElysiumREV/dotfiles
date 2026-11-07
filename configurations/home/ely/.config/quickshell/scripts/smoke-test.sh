#!/usr/bin/env bash
# Smoke test for the running Quickshell instance.
#
# Opens and closes every panel through IPC and fails if the Quickshell log shows
# QML errors while doing so (TypeError, ReferenceError, binding loops, ...).
# Run it inside the Hyprland session after changing the shell:
#
#   scripts/smoke-test.sh           open/close every panel
#   scripts/smoke-test.sh --reload  force a config reload first
#
# Panels flash on screen for ~2 seconds each. It cannot click anything, so
# interactions (Wi-Fi/Bluetooth, sliders, ...) still need a manual check.
set -u

SETTLE="${SMOKE_SETTLE:-2}"
PANELS=(
    toggleLauncher
    toggleVolumeMixer
    toggleShortcutHub
    toggleNotificationCenter
    toggleClipboardHistory
    toggleKeybindCheatsheet
    toggleWallpaper
    toggleWallhaven
    toggleLogout
)
# Known harmless noise from the environment, not from the shell code.
IGNORE='portal|textinput|kitty\.png|Could not load icon|Invalid path data|different thread'
FAILURES='ERROR|TypeError|ReferenceError|Binding loop|Unable to assign|is not a function|is not defined|Cannot read property|Cannot assign|Type .* unavailable|is not installed'

command -v qs >/dev/null 2>&1 || { echo "[Error] qs not found." >&2; exit 2; }
qs ipc show >/dev/null 2>&1 || { echo "[Error] No running Quickshell instance." >&2; exit 2; }

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$(mktemp)"
trap 'kill "${FOLLOWER:-0}" 2>/dev/null; rm -f "$LOG"' EXIT

strip_ansi() { sed 's/\x1b\[[0-9;]*m//g'; }

qs log -f >"$LOG" 2>&1 &
FOLLOWER=$!
sleep 1
MARK=$(wc -l <"$LOG")

if [ "${1:-}" = "--reload" ]; then
    echo "[Smoke] Forcing reload..."
    touch "$CONFIG_DIR/shell.qml"
    for _ in $(seq 1 20); do
        sleep 0.5
        tail -n +"$((MARK + 1))" "$LOG" | strip_ansi | grep -q "Configuration Loaded" && break
    done
fi

for panel in "${PANELS[@]}"; do
    echo "[Smoke] $panel"
    qs ipc call shell "$panel" >/dev/null 2>&1 || echo "[Warning] IPC call failed: $panel" >&2
    sleep "$SETTLE"
    qs ipc call shell "$panel" >/dev/null 2>&1
    sleep 1
done

sleep 1
kill "$FOLLOWER" 2>/dev/null
FOUND=$(tail -n +"$((MARK + 1))" "$LOG" | strip_ansi | grep -E "$FAILURES" | grep -Ev "$IGNORE")

if [ -n "$FOUND" ]; then
    echo
    echo "[Failed] The log reported problems:"
    echo "$FOUND"
    exit 1
fi
echo "[OK] No QML errors while opening ${#PANELS[@]} panels."
