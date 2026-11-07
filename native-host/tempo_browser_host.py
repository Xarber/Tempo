#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-only
"""Read-only Chrome Native Messaging bridge. Never accepts commands or file paths."""
import json
import math
import re
import select
import struct
import sys
import time
from pathlib import Path

HOST_NAME = 'org.openrecode.tempo.browser'
STATE_FILE = Path.home() / 'Library/Application Support/OpenRecode/Tempo/browser-state.json'
DOMAIN = re.compile(r'^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$')
INACTIVE = {'schemaVersion': 1, 'enabled': False, 'expiresAt': 0, 'domains': []}

def read_policy(path=STATE_FILE, now=None):
    now = time.time() if now is None else now
    try:
        if path.stat().st_size > 100_000:
            return dict(INACTIVE)
        value = json.loads(path.read_text())
        expires = value.get('expiresAt')
        domains = value.get('domains')
        session_id = value.get('sessionID')
        if (value.get('schemaVersion') != 1 or value.get('enabled') is not True
            or not isinstance(expires, (int, float)) or not math.isfinite(expires)
            or not 0 < expires - now <= 31
            or not isinstance(domains, list) or len(domains) > 500
            or not all(isinstance(d, str) and DOMAIN.fullmatch(d) for d in domains)
            or not isinstance(session_id, str) or len(session_id) > 64):
            return dict(INACTIVE)
        return {'schemaVersion': 1, 'enabled': True, 'expiresAt': expires,
                'sessionID': session_id, 'domains': sorted(set(domains))}
    except (OSError, ValueError, TypeError, AttributeError):
        return dict(INACTIVE)

def read_message(stream):
    header = stream.read(4)
    if len(header) != 4:
        return None
    length = struct.unpack('=I', header)[0]
    if length > 4096 or length < 2:
        raise ValueError('Invalid native message size')
    payload = stream.read(length)
    if len(payload) != length:
        raise ValueError('Truncated native message')
    return json.loads(payload)

def write_message(stream, message):
    payload = json.dumps(message, allow_nan=False, separators=(',', ':')).encode()
    stream.write(struct.pack('=I', len(payload)))
    stream.write(payload)
    stream.flush()

def main():
    try:
        request = read_message(sys.stdin.buffer)
        if request != {'type': 'subscribe', 'schemaVersion': 1}:
            return
        previous = None
        last_sent = 0
        while True:
            now = time.time()
            policy = read_policy(now=now)
            if policy != previous or now - last_sent >= 5:
                write_message(sys.stdout.buffer, policy)
                previous = policy
                last_sent = now
            ready, _, _ = select.select([sys.stdin.buffer], [], [], 1)
            if ready:
                message = read_message(sys.stdin.buffer)
                if message is None:
                    break
                # Explicitly reject state-changing or arbitrary-file requests.
                if message != {'type': 'subscribe', 'schemaVersion': 1}:
                    break
    except (BrokenPipeError, OSError, ValueError, TypeError):
        pass

if __name__ == '__main__':
    main()
