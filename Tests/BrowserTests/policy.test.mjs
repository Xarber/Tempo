// SPDX-License-Identifier: AGPL-3.0-only
import test from 'node:test';
import assert from 'node:assert/strict';
import {sanitize, buildRules} from '../../extensions/chromium/policy.mjs';
const policy = {schemaVersion:1,enabled:true,expiresAt:1030,sessionID:'test',domains:['example.com']};
test('active main-frame GET redirect uses exact request domains and subdomains', () => {
  const rules=buildRules(policy,0,1000);assert.equal(rules.length,1);
  assert.deepEqual(rules[0].condition.requestDomains,['example.com']);
  assert.deepEqual(rules[0].condition.requestMethods,['get']);
  assert.equal(rules[0].action.redirect.extensionPath,'/blocked.html');
});
test('expired, malformed, future-anomalous and inactive policies fail open', () => {
  for(const value of [null, {}, {...policy,enabled:false}, {...policy,expiresAt:999}, {...policy,expiresAt:2000}, {...policy,domains:['https://evil.com']}, {...policy,domains:['127.0.0.1']}]) assert.deepEqual(buildRules(value,0,1000),[]);
});
test('temporary exception expires and does not modify source rules', () => {
  assert.deepEqual(buildRules(policy,1100,1000),[]);
  assert.equal(buildRules({...policy,expiresAt:1130},1100,1110).length,1);
  assert.deepEqual(policy.domains,['example.com']);
});
test('no private extra fields cross boundary and domain sets deduplicate', () => {
  const safe=sanitize({...policy,intention:'private',domains:['example.com','example.com']},1000);
  assert.equal(safe.intention,undefined);assert.deepEqual(safe.domains,['example.com']);
});
