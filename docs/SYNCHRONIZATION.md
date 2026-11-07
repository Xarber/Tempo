# Synchronization status

Not implemented; no network requests, account system or implicit cross-device transfer exists. SQLite is local storage, not synchronization. Export/import is explicit data portability, not live cross-device control.

Future service must use authenticated devices, secure credential storage, idempotency keys, version preconditions and deterministic conflicts. Preserve distinct offline completed work. A shared session should have one authoritative history ID and an audit trail. Prefer local trusted-peer transport where practical; use optional server coordination only when needed. Do not publish a backend that lacks authentication or pretend sample endpoints are secure synchronization.
