# Development and exact commands

## macOS

Requires macOS 14+, Swift 6 and a matching macOS SDK. No external Swift packages or dependency installation are needed. Open Package.swift in Xcode for source navigation.

```sh
swift test
scripts/build-macos.sh debug
open build/Tempo.app
scripts/build-macos.sh release
```

The bundle is created at build/Tempo.app, identifier org.openrecode.tempo. Do not launch the raw executable for notification tests. Menu bar controls remain available after closing the main window; use Open Tempo to return. Floating timer is opened from the toolbar or menu popover.

Local ad-hoc signing does not establish Developer ID signing, notarization or distribution eligibility. Launch at login requires a correctly installed app bundle and user approval through system settings; local build-path registration is not a release validation.

## Tests

`swift test` runs deterministic Swift Testing tests against injected clocks and temporary SQLite directories. Never point tests at production Application Support. See reports/VALIDATION.md for installed-toolchain workarounds and actual results.

## Installed preview Command Line Tools workaround

The current host has Swift 6.4 preview CLT. Its default macOS 27 SDK references a missing SwiftUI macro plugin. macOS 26.5 SDK is already installed and builds the app without downloading anything:

```sh
TEMPO_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk scripts/test.sh
TEMPO_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk scripts/build-macos.sh debug
```

Use `TEMPO_OUTPUT_DIR=build/session-workflows` to stage a bundle without replacing the existing build/Tempo.app. The new directory is created automatically.

No global xcode-select setting is changed. `scripts/test.sh` uses native SwiftPM plus explicit Testing framework search paths only for this opt-in CLT workaround. With a complete matching Xcode installation, use the ordinary commands above.

To isolate UI test data:

```sh
TEMPO_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk TEMPO_VARIANT=TempoQA scripts/build-macos.sh debug
open build/TempoQA.app
```

QA uses a separate bundle ID and `OpenRecode/TempoQA` directory, marks exports simulated, and cannot merge into recorded production data. Never import QA records into production.

## Data

Storage: ~/Library/Application Support/OpenRecode/Tempo/tempo.sqlite (WAL/SHM companions may be present). Export through History or Settings. Import JSON invokes a preview before merge. Existing records are preserved. Back up through JSON or copy the database only after cleanly quitting Tempo; do not copy only the main SQLite file while WAL is active.

## iOS, backend and release

No iOS Xcode app/extension target or synchronization backend exists yet, so no working physical-iPhone build, server start or backend migration command is provided. Do not fabricate these commands. Follow ROADMAP.md to complete them using full Xcode and actual signing/entitlements. No Android distribution is planned for this native Apple project.

The manual GitHub Actions workflow tests and packages macOS; beta/main pushes run it. testing has no automatic full-build trigger. There is no release publication step or remote repository authorization.
