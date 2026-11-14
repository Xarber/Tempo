# X-Center deployment — 2026-11-14

Tempo Web 0.1.0 is publicly served at https://tempo.xcenter.it from commit
`ccb8fd36bba6e352d7d2ff34812f62cb32f20197`. The appliance serves a versioned
static directory through Nginx and its existing wildcard TLS certificate.
All user records stay in browser storage. No dedicated API, database or sync
service is required.

Public HTTPS returned the expected commit on /version.json and HTTP 200
for the root, /focus, manifest and service worker with appropriate content
types. In the live browser, the focus workspace and Settings rendered.
The QA query did not enable QA mode, and Settings exposed no Developer Ideas
unlock or server address field. The earlier loopback test exercised timer,
history and offline behavior. Production browser interaction was limited
to workspace navigation and Settings to avoid writing sample sessions.

Local verification passed four web tests, 29 Swift tests and the macOS
development bundle build. GitHub Actions succeeded for
[all four mobile packaging jobs](https://github.com/Xarber/Tempo/actions/runs/43507029286)
and [web, browser-policy and macOS validation](https://github.com/Xarber/Tempo/actions/runs/43507029311).
The Android builds and device IPA are unsigned. Simulator and physical-device
runtime tests, signing and store distribution remain pending.

This was the first Tempo deployment. The staged release is retained. For
withdrawal or rollback, follow [deployment instructions](../DEPLOYMENT.md).
