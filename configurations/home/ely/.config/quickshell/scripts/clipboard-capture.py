#!/usr/bin/env python3
"""Bounded, line-framed text capture for wl-paste --watch.

Prints one JSON line per clipboard change: the text as a JSON string, or an
object {"ignored": reason} when the content must not enter the history.
"""

import json
import subprocess
import sys

MAX_BYTES = 128 * 1024
# Password managers (KeePassXC, Bitwarden, KDE apps...) offer this MIME type
# next to the text so clipboard histories can skip the secret.
PASSWORD_HINT = "x-kde-passwordManagerHint"


def offered_types():
    try:
        result = subprocess.run(["wl-paste", "--list-types"], capture_output=True,
                                text=True, timeout=1)
        return result.stdout.split()
    except (OSError, subprocess.SubprocessError):
        return []


def read_stdin():
    data = bytearray()
    oversized = False
    while True:
        chunk = sys.stdin.buffer.read(8192)
        if not chunk:
            break
        if not oversized:
            if len(data) + len(chunk) > MAX_BYTES:
                data.clear()
                oversized = True
            else:
                data.extend(chunk)
    return data, oversized


def main():
    # Check the hint before reading: the content is still the one wl-paste announced.
    secret = PASSWORD_HINT in offered_types()
    data, oversized = read_stdin()  # always drain stdin so wl-paste does not get SIGPIPE

    if secret:
        print(json.dumps({"ignored": "secret"}))
    elif oversized:
        print(json.dumps({"ignored": "oversized"}))
    else:
        text = data.decode("utf-8", errors="replace")
        print(json.dumps(text, ensure_ascii=True))


main()
