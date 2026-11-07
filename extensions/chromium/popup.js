// SPDX-License-Identifier: AGPL-3.0-only
async function refresh() {
  const value = await chrome.runtime.sendMessage({type:'status'});
  document.getElementById('status').textContent = value.error || (!value.connected ? 'Not connected. Install the local host.' : value.enabled ? `Focus rules active for ${value.domains} domains.` : value.snoozedUntil > Date.now()/1000 ? 'Website rules paused temporarily.' : 'Connected. No active website rules.');
}
document.getElementById('resume').addEventListener('click', async () => { await chrome.runtime.sendMessage({type:'resume'}); await refresh(); });
refresh().catch(() => { document.getElementById('status').textContent = 'Connection unavailable. Rules are inactive.'; });
