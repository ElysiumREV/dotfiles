#!/usr/bin/env python3
"""Bounded, line-framed text capture for wl-paste --watch."""

import json
import sys

MAX_BYTES = 128 * 1024
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

if oversized:
    print(json.dumps({"ignored": "oversized"}))
else:
    text = data.decode("utf-8", errors="replace")
    print(json.dumps(text, ensure_ascii=True))
