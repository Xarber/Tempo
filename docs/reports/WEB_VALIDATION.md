# Web and React Native validation — 2026-11-13

## Passed

- TypeScript checking and production Expo Web static export on macOS with Node.js 24.
- Four automated tests covering pause recovery, duplicate finish, timed completion, analytics boundaries and isolation of simulated archives.
- Codex browser against the production export on loopback, using the isolated QA namespace. Verified first entry from the root landing, returning via the logo, preserving the draft on re-entry, starting and pausing focus, retaining the paused countdown through reload, resuming, finishing and saving a reflection. History displayed separate active and paused durations. Created a project and a task.
- With the loopback server stopped and the connection refused, the browser reloaded the cached workspace. The bare QA root remembered entry. Project data survived the reload. Starting and finishing a break left the completed focus count at one.
- Expo release-mode JavaScript exports for iOS and Android generated Hermes bundles.

## Pending

- PWA installation on desktop and mobile, cross-browser testing, hosted HTTPS and service-worker upgrade with two live deployed builds.
- React Native simulator and physical-device runs, native package builds and platform integration checks.
- Verification of the macOS graphical surfaces is independent of this web report.
