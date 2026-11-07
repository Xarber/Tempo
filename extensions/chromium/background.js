// SPDX-License-Identifier: AGPL-3.0-only
import {inactive, sanitize, buildRules} from './policy.mjs';
let port;
let policy = inactive();
let snoozedUntil = 0;
let queue = Promise.resolve();
let expiryTimer;
let connected = false;
let lastError = '';

function enqueue(operation) {
  queue = queue.then(operation).catch(async () => {
    lastError = 'Website rules could not be applied. Disable the extension to remove its rules.';
    try { const old = await chrome.declarativeNetRequest.getSessionRules(); await chrome.declarativeNetRequest.updateSessionRules({removeRuleIds: old.map(rule => rule.id)}); } catch { /* status below reports this failure */ }
    await chrome.storage.session.set({status: {connected, enabled: false, error: lastError}});
  });
  return queue;
}
async function apply() {
  policy = sanitize(policy);
  const rules = buildRules(policy, snoozedUntil);
  const old = await chrome.declarativeNetRequest.getSessionRules();
  await chrome.declarativeNetRequest.updateSessionRules({removeRuleIds: old.map(rule => rule.id), addRules: rules});
  await chrome.storage.session.set({status: {connected, enabled: rules.length > 0, snoozedUntil, error: lastError, domains: policy.domains.length}});
  clearTimeout(expiryTimer);
  if (policy.enabled) expiryTimer = setTimeout(() => enqueue(apply), Math.max(1, policy.expiresAt * 1000 - Date.now() + 20));
}
function connect() {
  if (port) return;
  try {
    port = chrome.runtime.connectNative('org.openrecode.tempo.browser');
    port.onMessage.addListener(value => enqueue(async () => {
      const next = sanitize(value);
      if (next.sessionID !== policy.sessionID) snoozedUntil = 0;
      policy = next; connected = true; lastError = ''; await apply();
    }));
    port.onDisconnect.addListener(() => {
      const detail = chrome.runtime.lastError?.message;
      port = undefined; connected = false; policy = inactive();
      lastError = detail ? 'Local host unavailable. See setup instructions.' : '';
      enqueue(apply);
    });
    port.postMessage({type: 'subscribe', schemaVersion: 1});
  } catch { port = undefined; policy = inactive(); connected = false; lastError = 'Local host unavailable.'; enqueue(apply); }
}
chrome.runtime.onMessage.addListener((message, sender, respond) => {
  // Extension pages only. No content scripts or externally_connectable entry point exist.
  if (sender.id !== chrome.runtime.id || !sender.url?.startsWith(chrome.runtime.getURL(''))) return false;
  if (message?.type === 'snooze') {
    enqueue(async () => { snoozedUntil = Date.now() / 1000 + 300; await chrome.alarms.create('tempo-snooze', {when: snoozedUntil * 1000}); await apply(); respond({ok: true}); });
    return true;
  }
  if (message?.type === 'resume') { enqueue(async () => { snoozedUntil = 0; await apply(); respond({ok: true}); }); return true; }
  if (message?.type === 'status') { chrome.storage.session.get('status').then(data => respond(data.status ?? {connected: false, enabled: false})); return true; }
  return false;
});
chrome.alarms.onAlarm.addListener(() => { connect(); enqueue(apply); });
chrome.runtime.onStartup.addListener(() => { connect(); enqueue(apply); });
chrome.runtime.onInstalled.addListener(() => { connect(); enqueue(apply); });
chrome.alarms.create('tempo-reconnect', {periodInMinutes: 0.5});
enqueue(apply);
connect();
