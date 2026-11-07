# SPDX-License-Identifier: AGPL-3.0-only
import importlib.util
import io
import json
import struct
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('host', ROOT / 'native-host/tempo_browser_host.py')
host = importlib.util.module_from_spec(spec)
spec.loader.exec_module(host)
class HostTests(unittest.TestCase):
    def policy(self, **changes):
        value = {'schemaVersion': 1, 'enabled': True, 'sessionID': 'test', 'expiresAt': 1030, 'domains': ['example.com']}
        value.update(changes)
        return value
    def read(self, value):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'policy.json'
            path.write_text(json.dumps(value))
            return host.read_policy(path, 1000)
    def test_valid_minimal_policy(self):
        self.assertEqual(self.read(self.policy()), self.policy())
        self.assertNotIn('intention', self.read(self.policy(intention='private')))
    def test_expiry_and_clock_anomaly_fail_open(self):
        for expiry in [999, 1000, 1032, 99999, float('nan')]:
            self.assertFalse(self.read(self.policy(expiresAt=expiry))['enabled'])
    def test_invalid_domains_and_shapes_fail_open(self):
        for domains in [['https://example.com'], ['-bad.com'], ['example.com/path'], ['127.0.0.1'], 'example.com', [3], ['example.com']*501]:
            self.assertFalse(self.read(self.policy(domains=domains))['enabled'])
        self.assertFalse(self.read([])['enabled'])
    def test_missing_or_corrupt_file_fails_open(self):
        self.assertFalse(host.read_policy(Path('/nonexistent/tempo/test'),1000)['enabled'])
    def test_native_framing_and_limits(self):
        stream=io.BytesIO();host.write_message(stream,self.policy());stream.seek(0)
        self.assertEqual(host.read_message(stream),self.policy())
        with self.assertRaises(ValueError): host.read_message(io.BytesIO(struct.pack('=I',50000)))
        with self.assertRaises(ValueError): host.read_message(io.BytesIO(struct.pack('=I',10)+b'{}'))
    def test_host_process_read_only_protocol(self):
        with tempfile.TemporaryDirectory() as folder:
            policy_path=Path(folder)/'browser-state.json'
            policy_path.write_text(json.dumps(self.policy(expiresAt=time.time()+30)))
            source=(ROOT/'native-host/tempo_browser_host.py').read_text()
            source=source.replace("STATE_FILE = Path.home() / 'Library/Application Support/OpenRecode/Tempo/browser-state.json'", "STATE_FILE = Path("+repr(str(policy_path))+")")
            executable=Path(folder)/'host.py';executable.write_text(source)
            def run(message):
                stream=io.BytesIO();host.write_message(stream,message)
                return subprocess.run([sys.executable,str(executable)],input=stream.getvalue(),capture_output=True,timeout=3)
            valid=run({'type':'subscribe','schemaVersion':1})
            self.assertEqual(valid.returncode,0)
            self.assertTrue(host.read_message(io.BytesIO(valid.stdout))['enabled'])
            forbidden=run({'type':'readFile','path':'/etc/passwd'})
            self.assertEqual(forbidden.stdout,b'')
    def test_installer_only_writes_isolated_root_and_rejects_bad_id(self):
        with tempfile.TemporaryDirectory() as folder:
            result = subprocess.run([sys.executable,str(ROOT/'scripts/install-browser-host.py'),'--extension-id','a'*32,'--output-root',folder],capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)
            manifest=Path(folder)/'Google/Chrome/NativeMessagingHosts/org.openrecode.tempo.browser.json'
            value=json.loads(manifest.read_text())
            self.assertEqual(value['allowed_origins'],['chrome-extension://'+'a'*32+'/'])
            self.assertTrue(Path(value['path']).is_file())
            bad=subprocess.run([sys.executable,str(ROOT/'scripts/install-browser-host.py'),'--extension-id','../bad','--output-root',folder],capture_output=True)
            self.assertNotEqual(bad.returncode,0)
if __name__=='__main__':unittest.main()
