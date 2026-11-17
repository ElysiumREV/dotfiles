#!/usr/bin/env bash
# Google Drive in Dolphin through rclone, one rclone remote per Google account,
# each mounted at ~/GoogleDrive/<name>.
#
#   gdrive.sh                 account chooser (Quickshell), or opens the only account
#   gdrive.sh list            "name<TAB>mounted(0|1)" for each Drive remote
#   gdrive.sh open NAME       mount if needed and open in Dolphin
#   gdrive.sh add NAME        log in to a new account (terminal + browser), then open
#   gdrive.sh unmount [NAME]  unmount one account, or all of them
#
# Tokens live in ~/.config/rclone/rclone.conf (not in the dotfiles). To forget
# an account: unmount it, then `rclone config delete NAME`.
# KDE's own Google account (kio-gdrive) no longer has Drive access.

set -u

BASE="$HOME/GoogleDrive"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/rclone"

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

mounted() {
	mountpoint -q "$BASE/$1"
}

open_account() {
	local name=$1 dir="$BASE/$1"
	if ! has_remote "$name"; then
		notify "No account named '$name'."
		return 1
	fi
	if ! mounted "$name"; then
		mkdir -p "$dir"
		if ! rclone mount "$name:" "$dir" --daemon \
			--vfs-cache-mode full --cache-dir "$CACHE" \
			--dir-cache-time 1h --poll-interval 1m \
			--volname "Google Drive ($name)"; then
			notify "Could not mount '$name' (run: gdrive.sh open $name)."
			return 1
		fi
	fi
	setsid -f dolphin --new-window "$dir" >/dev/null 2>&1
}

unmount_account() {
	local name=$1
	if mounted "$name"; then
		fusermount3 -u "$BASE/$name" 2>/dev/null || fusermount3 -uz "$BASE/$name"
	fi
	rmdir "$BASE/$name" 2>/dev/null
	return 0
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
	kitty --title "Google Drive" sh -c "
		echo 'Connecting Google Drive as \"$name\" (a browser window will open)...'
		echo 'Pick the right Google account there.'
		rclone config create '$name' drive scope=drive || { echo; echo 'Failed. Press Enter to close.'; read _; }
	"
	if has_remote "$name"; then
		open_account "$name"
	else
		notify "'$name' was not connected."
		exit 1
	fi
	;;
unmount)
	if [[ -n "$name" ]]; then
		unmount_account "$name"
	else
		while read -r r; do
			[[ -n "$r" ]] && unmount_account "$r"
		done < <(remotes)
	fi
	rmdir "$BASE" 2>/dev/null
	notify "Unmounted."
	;;
*)
	echo "usage: gdrive.sh [list | open NAME | add NAME | unmount [NAME]]" >&2
	exit 2
	;;
esac
