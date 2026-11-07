# Session workflows validation — 2026-11-07

## Implemented scope

Optional cycle continuation, independent opt-in for automatic breaks/next focus/continuation after long breaks, live intention/project/task switching with immutable historical segment contexts, context revision records, self-reported interruptions with optional pause, History details, segment-based project/task analytics, CSV segment details, and per-session notification IDs. The timer coordinator now requires successful persistence before beginning the next phase.

New core values and optional Codable properties preserve version-1 archives. Legacy timing segments acquire their original context before a switch. Existing completed work is not reassigned to the latest selected project. Context changes arriving after a deadline are rejected after capping completion at the deadline.

## Automated verification

Executed:

```sh
TEMPO_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk scripts/test.sh
```

29 tests passed in 3 suites, including parameterized domain cases. New tests cover segment-level task/project attribution, switching while paused, legacy context freezing, interruption logging with and without pause, automatic cycle opt-in and long-break stop policy, expired context edits, terminal edit rejection and JSON round trip. Existing timer, SQLite, portability, provenance and browser-policy tests also passed. SwiftUI source compiled as part of the test/build process.

## Native verification gate

Attempted to open the rebuilt TempoQA bundle through native computer control. The tool reported that the Mac is locked and automatic unlock failed. The user was asked to unlock it; no UI interactions or new workflow smoke test were completed. Previously recorded native timer evidence in VALIDATION.md applies to the earlier build, not these newly added controls. Automatic cycle orchestration, the new sheets, focus/keyboard behavior, notification delivery and actual sleep/wake remain unverified on the native UI.

## Git and release state

Retried the staged baseline Conventional Commit on testing. Hardware-backed SSH signing still failed with `device not found`; no commit was created and signing settings were preserved. No remote repository, push, publication or deployment occurred. No temporary branches/worktrees were created. beta/main remain pending the initial commit.

The previous build/Tempo.app bundle is preserved. New packaging is staged separately under build/session-workflows. Local ad-hoc signatures are development signing, not notarization or a public release. See the build evidence appended below.

## Build evidence

Optimized macOS ARM64 build succeeded in 26.05 seconds. Packaged standard and QA bundles at `build/session-workflows/Tempo.app` and `TempoQA.app`. Both passed Info.plist validation and strict/deep codesign verification with local ad-hoc signatures. Packaging the standard variant reused the same optimized executable; no release or notarization is claimed. Preview CLT linker search-path warnings remain nonfatal.

The previous `build/Tempo.app` is preserved as the rollback target. The new GUI remains unverified while the Mac is locked. iOS device/Simulator builds were not run; Android builds do not apply to the current native Apple project. No external deployment occurred.

Archive: `build/session-workflows/Tempo-session-workflows-arm64.zip`

SHA-256: `1ec4d27da0f299fe263b9e758a7fc9bdc0d13a14d083732fcddedc1dd71ab3da`
