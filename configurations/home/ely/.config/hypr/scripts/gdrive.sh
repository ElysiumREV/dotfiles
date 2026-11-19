#!/usr/bin/env bash
# Google Drive in Dolphin through rclone, one rclone remote per Google account,
# each mounted at ~/GoogleDrive/<name> by the systemd user unit
# rclone-gdrive@<name>.service (logs: journalctl --user -u rclone-gdrive@NAME).
#
#   gdrive.sh                 account chooser (Quickshell), or opens the only account
#   gdrive.sh list            "name<TAB>mounted(0|1)" for each Drive remote
#   gdrive.sh open NAME       mount if needed and open in Dolphin
#   gdrive.sh add NAME        log in to a new account (terminal + browser), then open
#   gdrive.sh unmount [NAME]  unmount one account, or all of them
#   gdrive.sh client          switch every account to your own Google API client
#
# Tokens live in ~/.config/rclone/rclone.conf (not in the dotfiles). To forget
# an account: unmount it, then `rclone config delete NAME`.
# KDE's own Google account (kio-gdrive) no longer has Drive access.

set -u

BASE="$HOME/GoogleDrive"
UNIT="rclone-gdrive"
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$UID}"
PLACES="${XDG_DATA_HOME:-$HOME/.local/share}/user-places.xbel"
SELF=$(realpath "$0")

notify() {
	notify-send -a "Google Drive" -i folder-gdrive "Google Drive" "$1"
}

remotes() {
	rclone listremotes --type drive 2>/dev/null | sed 's/:$//'
}

has_remote() {
	remotes | grep -qxF "$1"
}

valid_name() {
	[[ "$1" =~ ^[A-Za-z0-9_-]+$ ]]
}

# live: mounted and answering; stale: left behind by a dead rclone
# ("Transport endpoint is not connected"); none: not mounted.
mount_state() {
	local dir="$BASE/$1"
	if ! grep -qF " $dir fuse.rclone " /proc/self/mounts; then
		echo none
	elif timeout 5 stat -t "$dir" >/dev/null 2>&1; then
		echo live
	else
		echo stale
	fi
}

mounted() {
	[[ $(mount_state "$1") == live ]]
}

unit() {
	printf '%s@%s.service' "$UNIT" "$1"
}

# Files written to the mount but not uploaded yet (needs the unit's rc socket).
pending_uploads() {
	local sock="$RUNTIME/$UNIT-$1.sock"
	[[ -S "$sock" ]] || return 1
	rclone rc --unix-socket "$sock" vfs/stats 2>/dev/null |
		jq -e '.diskCache | .uploadsInProgress + .uploadsQueued' 2>/dev/null
}

# ~/GoogleDrive in Dolphin's Places panel (added once; remove it there if unwanted,
# it comes back only if the entry is gone and an account is opened again).
ensure_place() {
	[[ -f "$PLACES" ]] || return 0
	grep -qF "href=\"file://$BASE\"" "$PLACES" && return 0
	grep -q '^</xbel>$' "$PLACES" || return 0
	local tmp
	tmp=$(mktemp) || return 0
	{
		sed '/^<\/xbel>$/d' "$PLACES"
		cat <<-EOF
		 <bookmark href="file://$BASE">
		  <title>Google Drive</title>
		  <info>
		   <metadata owner="http://freedesktop.org">
		    <bookmark:icon name="folder-gdrive"/>
		   </metadata>
		  </info>
		 </bookmark>
		</xbel>
		EOF
	} >"$tmp" && cat "$tmp" >"$PLACES" # same inode, so Dolphin notices the change
	rm -f "$tmp"
}

open_account() {
	local name=$1
	if ! has_remote "$name"; then
		notify "No account named '$name'."
		return 1
	fi
	# A stale mount is cleared by the unit before mounting again.
	if ! mounted "$name" && ! systemctl --user start "$(unit "$name")"; then
		notify "Could not mount '$name'. Details: journalctl --user -u $(unit "$name")"
		return 1
	fi
	mkdir -p "$BASE"
	ensure_place
	setsid -f dolphin --new-window "$BASE/$name" >/dev/null 2>&1
}

# Returns 1 (and says why) when the account is busy and was left mounted.
unmount_account() {
	local name=$1 dir="$BASE/$1" n pids apps
	case $(mount_state "$name") in
	live)
		if n=$(pending_uploads "$name") && ((n > 0)); then
			notify "'$name' is still uploading $n file(s); try again in a moment."
			return 1
		fi
		pids=$(fuser -m "$dir" 2>/dev/null | xargs)
		if [[ -n "$pids" ]]; then
			apps=$(ps -o comm= -p "${pids// /,}" | sort -u | paste -sd, | sed 's/,/, /g')
			notify "'$name' is in use by ${apps:-another program}; close it and try again."
			return 1
		fi
		if systemctl --user -q is-active "$(unit "$name")"; then
			systemctl --user stop "$(unit "$name")"
		else
			# Mounted by an older gdrive.sh (rclone --daemon), outside the unit.
			fusermount3 -u "$dir"
		fi || {
			notify "Could not unmount '$name'."
			return 1
		}
		;;
	stale)
		systemctl --user stop "$(unit "$name")" 2>/dev/null
		fusermount3 -uz "$dir"
		;;
	none)
		systemctl --user stop "$(unit "$name")" 2>/dev/null
		;;
	esac
	rmdir "$dir" 2>/dev/null
	return 0
}

unmount_all() {
	local r ok=0
	while read -r r; do
		[[ -n "$r" ]] || continue
		unmount_account "$r" || ok=1
	done < <(remotes)
	return $ok
}

# Run in a terminal by `add`: log in with Google in the browser. Reuses the
# Google API client of an existing account (see `client`), if there is one.
add_tty() {
	local name=$1 client=() id secret
	id=$(rclone config dump 2>/dev/null |
		jq -r '[.[] | select(.type == "drive" and (.client_id // "") != "")][0] | .client_id // empty')
	secret=$(rclone config dump 2>/dev/null |
		jq -r '[.[] | select(.type == "drive" and (.client_id // "") != "")][0] | .client_secret // empty')
	[[ -n "$id" ]] && client=(client_id="$id" client_secret="$secret")
	echo "Connecting Google Drive as \"$name\" (a browser window will open)..."
	echo "Pick the right Google account there."
	if ! rclone config create "$name" drive scope=drive "${client[@]}"; then
		echo
		read -rp "Failed. Press Enter to close." _
	fi
}

# Run in a terminal by `client`: ask for the client ID/secret, then log in again
# with every account (a token belongs to the client that issued it).
client_tty() {
	local id secret r failed=0
	cat <<-'EOF'
	Without its own client, rclone shares Google's API quota with every other
	rclone user, which shows up as slow listings and "rateLimitExceeded" errors.

	1. https://console.cloud.google.com/ → create a project.
	2. APIs & Services → Library → enable "Google Drive API".
	3. OAuth consent screen: External; add your Google accounts as test users,
	   then "Publish app" (in "Testing" mode the login expires every 7 days;
	   published-but-unverified is fine for personal use).
	4. Credentials → Create credentials → OAuth client ID → "Desktop app".

	EOF
	read -rp "Client ID: " id
	read -rsp "Client secret: " secret
	echo
	if [[ -z "$id" || -z "$secret" ]]; then
		read -rp "Nothing changed. Press Enter to close." _
		return 1
	fi
	while read -r r; do
		[[ -n "$r" ]] || continue
		echo
		echo "=== $r: log in with the '$r' Google account in the browser ==="
		rclone config update "$r" client_id="$id" client_secret="$secret" </dev/tty || failed=1
	done < <(remotes)
	echo
	if ((failed)); then
		read -rp "Some accounts failed (run gdrive.sh client again). Press Enter to close." _
	else
		read -rp "Done. Press Enter to close." _
	fi
}

if ! command -v rclone >/dev/null; then
	notify "rclone is not installed."
	exit 1
fi

cmd=${1:-}
name=${2:-}

case "$cmd" in
"")
	qs ipc call shell toggleGoogleDrive >/dev/null 2>&1 && exit 0
	# No Quickshell: open the single account, or say how to pick one.
	mapfile -t list < <(remotes)
	if ((${#list[@]} == 1)); then
		open_account "${list[0]}"
	else
		notify "Use: gdrive.sh open NAME / gdrive.sh add NAME"
	fi
	;;
list)
	while read -r r; do
		[[ -n "$r" ]] || continue
		mounted "$r" && m=1 || m=0
		printf '%s\t%s\n' "$r" "$m"
	done < <(remotes)
	;;
open)
	open_account "$name"
	;;
add)
	if ! valid_name "$name"; then
		notify "Account name: letters, numbers, - and _ only."
		exit 1
	fi
	if rclone listremotes 2>/dev/null | grep -qxF "$name:"; then
		notify "'$name' already exists."
		exit 1
	fi
	notify "Log in with the '$name' Google account in the browser."
	kitty --title "Google Drive" "$SELF" _add-tty "$name"
	if has_remote "$name"; then
		open_account "$name"
	else
		notify "'$name' was not connected."
		exit 1
	fi
	;;
_add-tty)
	add_tty "$name"
	;;
unmount)
	if [[ -n "$name" ]]; then
		unmount_account "$name" && notify "'$name' unmounted."
	else
		unmount_all && notify "Unmounted."
	fi
	;;
client)
	if ! unmount_all; then
		notify "Unmount every account before switching the API client."
		exit 1
	fi
	kitty --title "Google Drive" "$SELF" _client-tty
	;;
_client-tty)
	client_tty
	;;
*)
	echo "usage: gdrive.sh [list | open NAME | add NAME | unmount [NAME] | client]" >&2
	exit 2
	;;
esac
