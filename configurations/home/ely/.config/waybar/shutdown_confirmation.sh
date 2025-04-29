#!/bin/bash

# Use wofi to ask for confirmation
CHOICE=$(echo -e "Yes\nNo" | wofi --dmenu --p "Are you sure you want to shutdown?" --lines 2)

# Check user choice and act accordingly
if [[ "$CHOICE" == "Yes" ]]; then
  shutdown now
fi

