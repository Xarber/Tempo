# Validation — 2026-11-06

## Scope and environment

TempoCore timer, SQLite persistence, portability and calendar-day calculations; macOS AppStore and SwiftUI app surfaces. Apple Silicon host, Swift 6.4 preview Command Line Tools, macOS 26.5 SDK, declared minimum macOS 14. No iOS SDK/Xcode build was executed. The installed Xcode-beta.app entry is a broken symlink, not a usable full Xcode installation.

## Automated checks

22 Swift Testing tests passed in two suites (including parameterized domain cases). Seven Python tests and four Node tests also passed for the browser policy, framing, read-only host subprocess and isolated installer. Executed with:

```sh
TEMPO_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk scripts/test.sh
```

Coverage: pause exclusion, delayed deadline completion, duplicate finish, invalid actions, extension/reduction without lost work, break exclusion, stopwatch, recovery across process/reboot samples, clock discontinuity, paused recovery, cycle break selection, SQLite/JSON round trip, duplicate merge, invalid imports, CSV formula neutralization, midnight split, actual Europe/Rome DST fallback, domain validation, opt-in browser leases and rejection of simulated exports into recorded history.

Injected sleep/reboot samples test arithmetic; they do not establish physical sleep/reboot behavior. No synchronization service exists, so simultaneous-device/auth tests were not run.

## Native desktop observations

Used actual build/TempoQA.app with independent `OpenRecode/TempoQA` Application Support storage, never the production Tempo database. Observed:

- Created QA project and tasks; a committed project-picker selection persisted the project association.
- Started session from a task, paused, opened floating timer, observed the same frozen 24:56 countdown, resumed from floating timer.
- Finished and saved reflection. History displayed 00:12 active and 00:14 paused with the entered reflection.
- Closed the main window during a second session; process remained running. Quit/reopened, restored active timer and visible estimated-recovery notice.
- Skipped optional reflection successfully. Started/finished a separate short break. Analytics displayed real local records and excluded break focus.
- Final rebuilt QA bundle completed a real one-minute countdown automatically while other settings were open, then offered optional reflection. History displayed exactly 01:00 active, Completed.
- Saved TempoQA-validation-20261106.json through the native save panel, reopened it through native import, reviewed counts (5 sessions, 1 project, 2 tasks, 1 idea), merged and observed the same five history rows without duplicates. Core export/restore round trip also passed.
- First-pass automation entered a malformed export filename; that QA file was moved into ignored build storage. Final export filename and import were verified through the actual file panels.

Menu bar extra compiles, but the computer-use bridge could not access its system-menu item after main-window closure. Menu bar independent controls remain unverified. Floating timer controls were verified. No OS notification authorization, audible/banner delivery, login registration, Dock policy toggle, app reminder trigger, physical sleep/wake, multi-display, VoiceOver or light-mode audit was executed.

## Fixes from review

- Resolved Swift exclusivity errors and a SwiftUI/Core Settings type-name ambiguity.
- Used installed SDK 26.5 because SDK 27's SwiftUI macro implementation is missing in the preview CLT.
- Added framework search flags/native SwiftPM fallback for Testing macros missing from the preview default build system.
- Deadline reduction now preserves already recorded work, including multiple timing segments.
- Ensured countdown observation follows the UI heartbeat.
- Kept completion notification request available at the deadline and added foreground notification presentation.
- Fixed idle timer preview, restored focus duration after break and added project/task editors and precise custom minutes input. The rebuilt QA bundle showed the correct idle 25:00 preview and accepted precise one-minute duration input. Saved a local domain rule/profile and unlocked Developer Options with three version taps, then created a pending QA idea. Browser enable remained off; no extension was installed.

## Browser source tests

Seven Python tests passed, including actual native-host subprocess framing and rejection of arbitrary file-read requests, expiring/malformed policies, isolated installer registration and origin ID validation. Four Node tests passed for domain-based top-level GET redirect rules, expiry/fail-open behavior, temporary exception and private-field exclusion. Background/popup/reminder scripts passed Node syntax checks. No browser host was installed into the user's browser settings. Real-browser navigation, permissions and recovery remain unverified.

## Local macOS packaging

Optimized ARM64 build completed successfully in 29.15 seconds. Launched the actual build/Tempo.app bundle and observed an idle 25:00 focus screen with zero production history; QA records stayed separate. Bundle Info.plist validation and `codesign --verify --deep --strict` passed. Signature is ad-hoc, not Developer ID/notarized. Artifact is local development output, not a published release or known-commit release build. Preview CLT emitted missing search-path linker warnings, without build failure.

Local archive: build/Tempo-v0.1.0-macos-arm64-development.zip

SHA-256: `b470eac83c9441234f29c64e6463df688cba0472a793805b443524bad1b9ec56`

## Git and publication

Initial Conventional Commit was attempted on testing. The user's global Git configuration requires SSH hardware-key signing (`commit.gpgsign=true`, `gpg.format=ssh`). Signing failed with `device not found`; no commit object was created. The key/unsigned-local-commit question is pending. testing is initialized; beta/main cannot receive baseline commit references until the initial commit exists. No temporary branches or worktrees were created, so none require cleanup. Signing configuration was not changed. No remote repository, push, release, notarization or deployment occurred.

## Outstanding gates

All broader gaps are listed in ../ROADMAP.md. This is not a full-app security/performance/accessibility audit, signed release or production deployment. Local bundle is ad-hoc signed; no notarization or remote workflow was run.
