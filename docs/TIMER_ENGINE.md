# Timer engine

## Authority

TimerEngine stores a FocusSession with ordered active/pause segments. Snapshot duration equals saved segment elapsed plus nonnegative continuous sample delta. AppStore samples Swift ContinuousClock, which includes sleep, independently of rendering. The one-second task is presentation/reconciliation only. A deadline task and local notification request are rescheduled on actions.

Start rejects an already active timer. Pause closes active time and opens a pause segment. Resume does the inverse. Finish closes either state. Finish/abandon on an already terminal completed/abandoned session is idempotent. Deadline reconciliation caps actual active duration to the planned duration, even after delayed wake. Break segments have active time but contribute zero focus. Open-ended/stopwatch modes have no deadline. Duration adjustment is bounded to 1 second–24 hours.

## Persistence and recovery

Commands save immediately. Active state checkpoints every 15 seconds and on explicit Quit. SQLite snapshot writes are transactional. During a live process wall-clock changes do not alter measured duration. Across process restart or device reboot monotonic anchors are discarded. The engine estimates unsaved elapsed time from the last segment wall timestamp, marks the recovery estimate in history, and continues or completes the timer. A backward discontinuity greater than two seconds or forward gap greater than seven days interrupts the session at its saved elapsed time for review.

A forward clock adjustment within the seven-day limit cannot be distinguished from time away across restart. This is a documented limitation; recovered duration is never labelled directly measured. Timezone changes affect display and day grouping, not elapsed seconds. A process killed during an adjustment may retain the previous complete snapshot, never a partial record.

## Cycle policy

Completed focus sessions increment the cycle counter once. The configured nth completion selects a long break. Manual phase start remains the default. Optional switches enable automatic breaks and subsequent focus at natural deadlines while the process runs; long breaks stop progression unless explicitly configured otherwise. Early finish, abandonment, duration reduction and process restoration do not auto-start a phase. Breaks remain separate records. Scheduled focus is not implemented. See features/SESSION_WORKFLOWS.md for context changes, interruption logging and exact cycle policy.

## Tests

See Tests/TempoCoreTests/TimerTests.swift. Injected sleep/clock/reboot scenarios are deterministic engine tests, not physical suspend/reboot validation. Remaining real-device gates are listed in the validation report.
