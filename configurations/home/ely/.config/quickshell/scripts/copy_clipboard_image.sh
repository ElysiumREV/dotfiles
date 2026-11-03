#!/usr/bin/env bash
set -euo pipefail

image_path="${1:?Missing screenshot path}"
if [[ ! -f "$image_path" || "$image_path" != "$HOME/Pictures/Screenshots/"*.png ]]; then
    printf 'Invalid screenshot path: %s\n' "$image_path" >&2
    exit 2
fi

wl-copy --type image/png < "$image_path"
