// SPDX-License-Identifier: AGPL-3.0-only
export const inactive = () => ({schemaVersion: 1, enabled: false, expiresAt: 0, domains: []});
export function sanitize(value, now = Date.now() / 1000) {
  const domain = /^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$/;
  if (!value || value.schemaVersion !== 1 || value.enabled !== true || !Number.isFinite(value.expiresAt)
      || value.expiresAt <= now || value.expiresAt - now > 31
      || typeof value.sessionID !== 'string' || value.sessionID.length > 64
      || !Array.isArray(value.domains) || value.domains.length > 500 || !value.domains.every(d => typeof d === 'string' && domain.test(d))) return inactive();
  return {schemaVersion: 1, enabled: true, sessionID: value.sessionID, expiresAt: value.expiresAt, domains: [...new Set(value.domains)].sort()};
}
export function buildRules(policy, snoozedUntil = 0, now = Date.now() / 1000) {
  const safe = sanitize(policy, now);
  if (!safe.enabled || snoozedUntil > now || safe.domains.length === 0) return [];
  return [{id: 1, priority: 1, action: {type: 'redirect', redirect: {extensionPath: '/blocked.html'}}, condition: {requestDomains: safe.domains, resourceTypes: ['main_frame'], requestMethods: ['get']}}];
}
