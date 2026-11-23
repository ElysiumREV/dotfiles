#!/usr/bin/env bash
# DNS servers of NetworkManager connection profiles (nmcli).
# Used by services/DnsControl.qml; also handy from a terminal.
#
#   dns.sh status                         main active connection (Wi-Fi or wired), key=value lines
#   dns.sh profiles                       saved Wi-Fi/Ethernet profiles: uuid<TAB>type<TAB>name
#   dns.sh set "<ipv4>" "<ipv6>" [uuid]   fixed servers (comma or space separated);
#                                         the DNS announced by the network is ignored
#   dns.sh reset [uuid]                   back to the DNS provided by the network
#
# Without a uuid, set/reset target the main active connection: the Wi-Fi or
# wired connection that carries the default route (lowest metric). The change is
# saved in the profile; if that profile is active it is applied right away with
# `nmcli device reapply` (no disconnection).
set -u

die() { echo "error=$*"; exit 1; }

command -v nmcli >/dev/null 2>&1 || die "nmcli is not installed."

# nmcli -g escapes ':' (IPv6) as '\:' and joins multiple values with ' | ' or ','.
clean_list() { sed -e 's/\\:/:/g' -e 's/ | /,/g' | paste -sd, - | sed -e 's/,,*/,/g' -e 's/^,//' -e 's/,$//'; }
normalize() { echo "${1:-}" | tr ' ;' ',,' | sed -e 's/,,*/,/g' -e 's/^,//' -e 's/,$//'; }

# Prints "uuid device type" of the main active connection.
active_main() {
    local candidates route_dev
    candidates=$(nmcli -t -f UUID,TYPE,DEVICE connection show --active \
        | awk -F: '$2 == "802-11-wireless" || $2 == "802-3-ethernet" { print $1, $3, $2 }')
    [ -n "$candidates" ] || return 0
    # Device of the default route with the lowest metric (e.g. cable over Wi-Fi).
    route_dev=$(ip -o route show default 2>/dev/null \
        | awk '{ m = 0; for (i = 1; i < NF; i++) { if ($i == "dev") d = $(i + 1); if ($i == "metric") m = $(i + 1) }
                 print m, d }' | sort -n | awk 'NR == 1 { print $2 }')
    if [ -n "$route_dev" ] && echo "$candidates" | awk -v d="$route_dev" '$2 == d { found = 1 } END { exit !found }'; then
        echo "$candidates" | awk -v d="$route_dev" '$2 == d { print; exit }'
    else
        echo "$candidates" | head -n 1
    fi
}

# Device of a profile if it is active, empty otherwise.
active_device() {
    nmcli -t -f UUID,DEVICE connection show --active | awk -F: -v u="$1" '$1 == u { print $2; exit }'
}

get() { nmcli -g "$2" connection show "$1" 2>/dev/null; }

ipv6_usable() {
    case "$(get "$1" ipv6.method)" in
        ignore|disabled) return 1 ;;
        *) return 0 ;;
    esac
}

modify_and_apply() {
    local uuid="$1"; shift
    local output device
    output=$(nmcli connection modify "$uuid" "$@" 2>&1) || die "$(echo "$output" | tail -n 1)"
    device=$(active_device "$uuid")
    if [ -n "$device" ]; then
        # reapply keeps the connection up; fall back to reconnecting if it is refused.
        nmcli device reapply "$device" >/dev/null 2>&1 \
            || nmcli connection up "$uuid" >/dev/null 2>&1 \
            || die "Saved, but NetworkManager could not apply it yet."
    fi
    echo "ok=1"
}

target() {
    if [ -n "${1:-}" ]; then
        echo "$1"
    else
        read -r uuid _ _ < <(active_main)
        [ -n "${uuid:-}" ] || die "No active network connection."
        echo "$uuid"
    fi
}

case "${1:-status}" in
    status)
        read -r uuid device type < <(active_main)
        [ -n "${uuid:-}" ] || die "No active network connection."
        echo "uuid=$uuid"
        echo "device=$device"
        echo "type=$([ "$type" = "802-3-ethernet" ] && echo wired || echo wifi)"
        echo "name=$(get "$uuid" connection.id)"
        echo "ipv4_dns=$(get "$uuid" ipv4.dns | clean_list)"
        echo "ipv4_ignore_auto=$(get "$uuid" ipv4.ignore-auto-dns)"
        echo "ipv6_dns=$(get "$uuid" ipv6.dns | clean_list)"
        echo "ipv6_ignore_auto=$(get "$uuid" ipv6.ignore-auto-dns)"
        echo "ipv6_method=$(get "$uuid" ipv6.method)"
        echo "current=$(nmcli -g IP4.DNS,IP6.DNS device show "$device" 2>/dev/null | clean_list)"
        ;;
    profiles)
        nmcli -t -f UUID,TYPE,NAME connection show \
            | awk -F: '$2 == "802-11-wireless" || $2 == "802-3-ethernet" {
                  name = $0; sub(/^[^:]*:[^:]*:/, "", name); gsub(/\\:/, ":", name)
                  print $1 "\t" $2 "\t" name }'
        ;;
    set)
        uuid=$(target "${4:-}") || { echo "$uuid"; exit 1; }
        ipv4=$(normalize "${2:-}")
        ipv6=$(normalize "${3:-}")
        [ -n "$ipv4$ipv6" ] || die "No DNS server given."
        args=(ipv4.dns "$ipv4" ipv4.ignore-auto-dns yes)
        if ipv6_usable "$uuid"; then
            args+=(ipv6.dns "$ipv6" ipv6.ignore-auto-dns yes)
        fi
        modify_and_apply "$uuid" "${args[@]}"
        ;;
    reset)
        uuid=$(target "${2:-}") || { echo "$uuid"; exit 1; }
        args=(ipv4.dns "" ipv4.ignore-auto-dns no)
        if ipv6_usable "$uuid"; then
            args+=(ipv6.dns "" ipv6.ignore-auto-dns no)
        fi
        modify_and_apply "$uuid" "${args[@]}"
        ;;
    *)
        die "Usage: dns.sh status | profiles | set <ipv4> <ipv6> [uuid] | reset [uuid]"
        ;;
esac
