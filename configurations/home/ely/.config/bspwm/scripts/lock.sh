#!/usr/bin/env bash

if command -v betterlockscreen >/dev/null 2>&1; then
  betterlockscreen -l dim
elif command -v i3lock-color >/dev/null 2>&1; then
  i3lock-color \
    --color=13151A \
    --inside-color=1A1D24ff \
    --ring-color=A08EC4ff \
    --line-color=00000000 \
    --keyhl-color=7EA3CCff \
    --bshl-color=C47A7Aff \
    --separator-color=00000000 \
    --insidever-color=1A1D24ff \
    --insidewrong-color=1A1D24ff \
    --ringver-color=7EBD9Bff \
    --ringwrong-color=C47A7Aff \
    --date-color=d4c5b0ff \
    --time-color=A08EC4ff \
    --verif-color=d4c5b0ff \
    --wrong-color=C47A7Aff
elif command -v i3lock >/dev/null 2>&1; then
  i3lock -c 13151A
else
  notify-send "Lockscreen" "Install betterlockscreen, i3lock-color or i3lock"
fi
