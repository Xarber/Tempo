# Specification coverage and remaining work

This is a development implementation, not completion of all 48 specification sections.

## Implemented (validation separately reported)

- Core focus/custom/break/stopwatch/open-ended timing, pause/resume, finish, abandon, extension/reduction and restart.
- Monotonic live timing, transactional SQLite snapshots, labelled wall-clock restart recovery.
- macOS focus, menu bar and floating windows; cycle-guided breaks, optional automatic phase progression and presets.
- Basic projects, tasks, segment-preserving live context changes, self-reported interruptions, optional reflection, recoverable history deletion, chart and project totals.
- JSON export/reviewed merge, CSV and Markdown report.
- Opt-in foreground-app reminders, saved distraction profiles, Chromium extension source with read-only expiring rule bridge, notification scheduling, login registration and Dock toggle.
- Developer unlock, diagnostics and local Ideas CRUD/search/filter/duplicate/import/export.

- Expo Web workspace, integrated root landing, local IndexedDB and an offline PWA shell.
- React Native focus timer and recent history with local SQLite. Device validation remains pending.

## Partial

Projects/tasks: name/description/status editing and task estimates are implemented; due dates, subtasks, reordering and project deletion still needed. Cycles: manual default plus optional automatic progression at live natural deadlines; newly added controls need native verification. Analytics: limited views and optional daily-minute goal. Ideas: no revision history, standalone interchange schema, batch operations or conflict-choice editor. Changelog: first-version static information; no persistent post-update popup or GitHub updater. Distraction management: app reminders and Chromium extension source; real-browser setup/navigation unverified. Persistence: transactional snapshot, not indexed normalized tables. Extension seams exist; plugin registry is absent.

## Not implemented

Scheduled focus, templates, manual session entry, editable historical associations/audit log, advanced analytics/goals, Safari/Firefox website blocking, allowlists, scheduled restrictions, calendar integration, AppleScript, App Intents, widgets, ActivityKit, full iOS companion parity, sounds, sync backend/auth/device controls, P2P, update checks/self-updates, release manifests, release publication, and public distribution.

## Next delivery order

1. Pass core/build checks and actual macOS timer/menu/floating/history scenarios.
2. Harden deadline notifications, lifecycle persistence and analytics clock-discontinuity placement; finish project/task editing and cycle behavior.
3. Validate Chromium extension in a real browser, then extend browser/profile lifecycle with verified recovery.
4. Add iOS Xcode targets, widgets/Live Activities/App Intents and physical tests.
5. Implement optional authenticated self-hosted sync with conflict tests.
6. Calendar, automation, update/release system, security/accessibility/performance and notarized distribution after authorization.

Never mark a capability complete on the basis of uncompiled source or mock UI.
