#!/usr/bin/env bash
# Default handler for web links (see ~/.local/share/applications/browser-chooser.desktop):
# asks Quickshell which browser opens the URL. Without a running Quickshell the
# link still opens, in Firefox, so it is never lost.
url=${1:-}
qs ipc call shell openBrowserChooser "$url" >/dev/null 2>&1 && exit 0
exec firefox ${url:+"$url"}
