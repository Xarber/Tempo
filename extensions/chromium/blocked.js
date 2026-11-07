// SPDX-License-Identifier: AGPL-3.0-only
const status = document.getElementById('status');
document.getElementById('back').addEventListener('click', () => { if (history.length > 1) history.back(); else window.close(); });
document.getElementById('snooze').addEventListener('click', async () => {
  try { await chrome.runtime.sendMessage({type: 'snooze'}); status.textContent = 'Website rules paused for five minutes. You can revisit the website.'; }
  catch { status.textContent = 'Could not pause rules. You can disable the extension through your browser.'; }
});
