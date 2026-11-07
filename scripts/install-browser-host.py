#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-only
"""Run explicitly after loading the unpacked extension. Installs only for this user."""
import argparse
import json
import os
import re
import sys
from pathlib import Path
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--extension-id', required=True, help='32-character ID shown by Chrome for this extension')
parser.add_argument('--browser', choices=['chrome', 'chromium', 'edge'], default='chrome')
parser.add_argument('--output-root', type=Path, help='Test-only installation root; avoids real browser configuration')
args = parser.parse_args()
if not re.fullmatch(r'[a-p]{32}', args.extension_id):
    parser.error('Extension ID must contain exactly 32 lowercase a–p characters')
root = args.output_root if args.output_root else Path.home() / 'Library/Application Support'
paths = {'chrome': 'Google/Chrome/NativeMessagingHosts', 'chromium': 'Chromium/NativeMessagingHosts', 'edge': 'Microsoft Edge/NativeMessagingHosts'}
name = 'org.openrecode.tempo.browser'
host_dir = root / 'OpenRecode/Tempo/BrowserHost'
host = host_dir / 'tempo_browser_host.py'
manifest = root / paths[args.browser] / (name + '.json')
source = (Path(__file__).resolve().parent.parent / 'native-host/tempo_browser_host.py').read_text()
if '\n' in sys.executable or ' ' in sys.executable:
    parser.error('Python interpreter path must have no spaces or newlines for a native-host shebang')
content = '#!' + sys.executable + '\n' + source.split('\n', 1)[1]
payload = {'name': name, 'description': 'Tempo local focus rules (read-only)', 'path': str(host.resolve()), 'type': 'stdio', 'allowed_origins': ['chrome-extension://' + args.extension_id + '/']}
if manifest.exists():
    old = json.loads(manifest.read_text())
    if old != payload:
        parser.error('A different host registration exists. Preserve it and reconcile manually before replacing it.')
host_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
manifest.parent.mkdir(parents=True, exist_ok=True)
for path, text, mode in [(host, content, 0o700), (manifest, json.dumps(payload, indent=2) + '\n', 0o600)]:
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(text)
    os.chmod(temporary, mode)
    temporary.replace(path)
print('Installed read-only host:', host)
print('Browser registration:', manifest)
print('No extensions or browser permissions were enabled automatically.')
