# Tempo development

Native macOS app, Swift 6, macOS 14+. No third-party Swift dependencies. AGPL-3.0-only.
Read docs/INDEX.md, docs/ARCHITECTURE.md and docs/TIMER_ENGINE.md before modifying timing.
Read docs/IDEAS.json at the start of substantial work; summarize pending/approved/deferred ideas, compare relevant implementations, and ask whether relevant ideas should be implemented now or later. Never implement unrelated ideas without authorization. Private on-device ideas require an authorized export. Never claim automatic retrieval without reading actual data.

Use `swift test`, then `scripts/build-macos.sh debug`. Launch the app bundle, not the raw executable (notifications require bundle identity). Check actual UI through native automation. Do not add sample history to production storage. Prefer a separate temporary application-support namespace for tests.

Develop on testing or temporary branches, integrate into testing, Conventional Commits. beta/main are promotions only. No public repository, releases or deployment authorized. No automatic full builds on testing. Preserve user data and unrelated changes. CI does not prove physical device behavior. Keep docs/reports and ROADMAP truthful about incomplete scope. Do not implement timers by decrementing counters. Never store credentials in client code. Do not add destructive restrictions to distraction reminders.

Expo SDK 57 supports the web workspace and React Native timer. Keep first-visit landing state in web routes and the SQLite adapter in native builds. Test the production web export in a browser with `?qa=1` and report simulator, native package and physical-device evidence separately. The existing Xarber/Tempo remote is public and its historical scaffold license is retained in LICENSES. Review release and publishing authorization before exposing new work. Use X-Center for authorized hosting.
