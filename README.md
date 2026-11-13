<p align="center"><img src="assets/branding/tempo.svg" width="120" alt="Tempo icon"></p>

# Tempo

**Make time for what matters.** Native, offline-first focus and time tracking for macOS, part of OpenRecode.

Development version 0.1.0. A functional macOS implementation is in progress; this repository does not yet implement the complete Project 07 specification. No account, cloud, advertisements, telemetry, or subscription is required.

## Run

Requires macOS 14+, a Swift 6 toolchain and the macOS SDK. No package installation is needed.

```sh
swift test
scripts/build-macos.sh debug
open build/Tempo.app
```

Open `Package.swift` in Xcode to edit. Closing the main window leaves Tempo in the menu bar. Quit explicitly from its popover. Local builds are ad-hoc signed and not notarized.

Implemented: timestamp/continuous-clock timer, pause/resume, deadline completion, focus/break/open-ended modes, menu bar, floating timer, SQLite persistence, recovery, project/task associations, reflections, history with recoverable deletion, analytics, portable exports/import review, optional local application reminders, saved distraction profiles, developer Ideas. Chromium extension source and local bridge are available with separate opt-in setup; real-browser verification remains open.

See [documentation](docs/INDEX.md), [status and remaining scope](docs/ROADMAP.md), [test report](docs/reports/VALIDATION.md), and [build instructions](docs/DEVELOPMENT.md). iOS, Live Activities, widgets, Safari/Firefox blocking, calendar integration and backend synchronization are not released capabilities.

Licensed AGPL-3.0-only. Copyright 2026 Tempo contributors. System frameworks and SQLite retain their own terms; no proprietary Session assets or source are used.

## Web and mobile

Use Node.js 24, run `npm ci`, then `npm run build:web` and `node scripts/serve-web.mjs`. Open `http://127.0.0.1:4173/`. See [web and React Native mobile](docs/WEB.md) for the supported workflows and [browser validation](docs/reports/WEB_VALIDATION.md) for test evidence.
