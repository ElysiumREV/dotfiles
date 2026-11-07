#!/usr/bin/env bash
# Sends a battery of test notifications to exercise the Quickshell notification server.
#
#   scripts/notify-test.sh            list the scenarios
#   scripts/notify-test.sh all        run every scenario (waits for you between them)
#   scripts/notify-test.sh <name>...  run only some scenarios
#
# Each scenario prints what you should see. Interactive ones (actions) report the
# action that was clicked, so you can confirm it reached the sender.
set -u

command -v notify-send >/dev/null 2>&1 || { echo "[Error] notify-send not found (libnotify)." >&2; exit 2; }

IMAGE="${NOTIFY_TEST_IMAGE:-$HOME/Pictures/Wallpapers/.current-wallpaper.png}"
SCENARIOS=(basic urgency timeouts long unicode icons image actions progress groups apps transient dnd)

say() { printf '\n\033[1m== %s\033[0m\n   %s\n' "$1" "$2"; }
pause() { [ "${NOTIFY_TEST_AUTO:-0}" = "1" ] || read -rp "   Press Enter for the next step..." _; }

scenario_basic() {
    say "basic" "A popup with a title and a short body, closing after the default duration."
    notify-send -a "Test: basic" "Hello from notify-send" "This is the body text."
}

scenario_urgency() {
    say "urgency" "Three popups: low, normal and critical. Critical should stay until dismissed and look different."
    notify-send -a "Test: urgency" -u low "Low urgency" "Quiet notification."
    sleep 1
    notify-send -a "Test: urgency" -u normal "Normal urgency" "Regular notification."
    sleep 1
    notify-send -a "Test: urgency" -u critical "Critical urgency" "Should not expire by itself."
}

scenario_timeouts() {
    say "timeouts" "1 s popup, 8 s popup, and one that never expires (-t 0). The app timeout wins over the default."
    notify-send -a "Test: timeouts" -t 1000 "Expires in 1 s" "Gone almost immediately."
    sleep 1.5
    notify-send -a "Test: timeouts" -t 8000 "Expires in 8 s" "Stays a while."
    sleep 1
    notify-send -a "Test: timeouts" -t 0 "Never expires" "Dismiss me manually."
}

scenario_long() {
    say "long" "A very long title and body: text should wrap or elide without overflowing the popup."
    notify-send -a "Test: long text" \
        "A very long notification title that keeps going to check how the popup handles overflow" \
        "$(printf 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. %.0s' 1 2 3 4 5 6)"
}

scenario_unicode() {
    say "unicode" "Accents, CJK and emoji should render (fallback fonts), and markup characters must not break the layout."
    notify-send -a "Test: unicode" "Ação, coração, 日本語 🎉" "Olá! <b>not bold</b> & <i>not italic</i> — emoji: 🔥🚀"
}

scenario_icons() {
    say "icons" "App icons must look like icons (small tile), never like an attached picture. A missing icon falls back to a bell."
    notify-send -a "Test: icons" -i firefox "App icon (firefox)" "Icon from the icon theme."
    sleep 1
    notify-send -a "Test: icons" -i dialog-warning "Themed icon" "dialog-warning"
    sleep 1
    notify-send -a "Test: icons" -i this-icon-does-not-exist "Missing icon" "Should not show a broken image."
    sleep 1
    notify-send -a "Test: icons" -i /usr/share/icons/hicolor/48x48/apps/firefox.png "Icon as a file path" "Small icon tile, not a picture preview."
}

scenario_image() {
    if [ ! -f "$IMAGE" ]; then
        say "image" "Skipped: $IMAGE not found (set NOTIFY_TEST_IMAGE)."
        return
    fi
    say "image" "A notification with an image attached (like chat apps with avatars or screenshots)."
    notify-send -a "Test: image" -h "string:image-path:$IMAGE" "Image notification" "Image from $IMAGE"
}

scenario_actions() {
    say "actions" "Click an action button (or the popup itself) within 15 s; the chosen action is printed here."
    local picked
    picked=$(timeout 20 notify-send -a "Test: actions" -u normal -t 15000 \
        -A "default=Open" -A "reply=Reply" -A "archive=Archive" \
        "Message with actions" "Click one of the buttons." 2>&1)
    echo "   Selected action: ${picked:-<none: dismissed or expired>}"
}

scenario_progress() {
    say "progress" "One popup that updates in place from 0 to 100 (same id, no new popups) and has a progress value."
    local id
    id=$(notify-send -a "Test: progress" -p -h int:value:0 "Copying files" "0%")
    for value in 20 40 60 80 100; do
        sleep 0.8
        notify-send -a "Test: progress" -r "$id" -h "int:value:$value" "Copying files" "$value%" >/dev/null
    done
}

scenario_groups() {
    say "groups" "Five notifications from the same app: the history should group them under one entry."
    for n in 1 2 3 4 5; do
        notify-send -a "Test: grouped app" -t 2500 "Grouped message $n" "Message number $n of 5"
        sleep 0.4
    done
}

scenario_apps() {
    say "apps" "Notifications from different apps: separate groups in the history, each with its own name."
    notify-send -a "Chat" -i mail-message-new "Alice" "Are you coming tonight?"
    sleep 0.6
    notify-send -a "Calendar" -i appointment-soon "Meeting in 10 minutes" "Daily stand-up"
    sleep 0.6
    notify-send -a "System" -i dialog-information "Update available" "12 packages can be upgraded."
}

scenario_transient() {
    say "transient" "A transient notification (-e): should show as a popup but NOT be kept in the history."
    notify-send -a "Test: transient" -e "Transient notification" "Check that it is absent from the history."
}

scenario_dnd() {
    say "dnd" "Do Not Disturb on: the next notification must not pop up but should appear in the history."
    qs ipc call shell toggleDoNotDisturb >/dev/null 2>&1
    sleep 1
    notify-send -a "Test: DND" "Sent while DND is on" "No popup expected; look in the history."
    pause
    qs ipc call shell toggleDoNotDisturb >/dev/null 2>&1
    echo "   Do Not Disturb toggled back."
}

list_scenarios() {
    echo "Scenarios: ${SCENARIOS[*]}"
    echo "Usage: $0 all | <scenario>..."
    echo "Server: $(gdbus call --session --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.GetCapabilities 2>/dev/null || echo unavailable)"
}

[ $# -eq 0 ] && { list_scenarios; exit 0; }
[ "$1" = "all" ] && set -- "${SCENARIOS[@]}"

for name in "$@"; do
    if declare -F "scenario_$name" >/dev/null; then
        "scenario_$name"
        pause
    else
        echo "[Warning] Unknown scenario: $name" >&2
    fi
done
echo
echo "[Done] Also check: open the panel (SUPER+O), Alerts tab: archive/remove one, clear all, then reload the shell."
