#!/usr/bin/env bash

if command -v clipmenu >/dev/null 2>&1; then
  clipmenu
elif command -v greenclip >/dev/null 2>&1; then
  rofi -modi "clipboard:greenclip print" -show clipboard -run-command '{cmd}'
else
  notify-send "Clipboard" "Install clipmenu or greenclip for clipboard history"
fi
