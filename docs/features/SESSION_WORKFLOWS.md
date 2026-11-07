# Session context, interruptions and optional cycle progression

## Scope

Implemented in TempoCore/SessionContext.swift, TimerEngine.swift and Analytics.swift; coordinated by AppStore and exposed through the active timer's More menu, editor sheets, History and cycle Settings. Existing timer controls remain available. Native smoke testing of these new controls is pending because the Mac was locked during the 2026-11-07 verification attempt.

## Changing intention, project or task

Use More → Edit intention or switch task during a running or paused session. Saving closes the current timing segment and opens a segment with the new context while preserving the running/paused state. Earlier intervals keep their original project/task association. A context revision stores timestamp, previous context and new context. Changing context does not restart the countdown, increase planned time or accrue focus while paused.

For version-1 records created before this feature, context-less segments use the session's existing metadata. Before the first live context change, the engine freezes those old segments with the original context. Project/task analytics sum active segments by their context, rather than assigning the entire session to its latest task. No completed work is silently reassigned. The latest session-level fields still identify the current/final context.

Changing context after a deadline reconciles completion first and rejects the edit. Completed history metadata editing is not implemented by this action. JSON preserves the complete segment/revision graph. CSV adds `segment_contexts_json`; its existing `project_id` field identifies the final context, so project analysis must use segment contexts for sessions with switches.

## Self-reported interruptions

More → Record interruption offers Notification, Website, Conversation, Phone call, Other task, Personal break and Other, an optional note (2,000 characters maximum), and an explicit Pause session toggle. Logging without pausing keeps focus time running. Logging with pause closes active time and starts a pause interval; ordinary Resume continues it. The interruption record stores the category, wall timestamp, note and requested pause flag. History displays these records.

These records are subjective, user-entered events. They do not imply automatic monitoring or that an application switch was a distraction. No window titles, typed content or browser activity is captured.

## Optional automatic cycles

All new switches default off when loading old data. Cycle Settings independently control automatic break start, automatic next-focus start, and continuing after long breaks. The cycle count still determines short versus long breaks. Reset cycle progress affects the counter only, never session history.

Automatic progression is permitted only for a naturally reached deadline while Tempo's process is running. Explicit Finish, Abandon, Restart, duration reduction that ends a session, and restoring an already completed session do not trigger another phase. Disabling cycle guidance disables progression. Long breaks stop the cycle unless continuing after long breaks is explicitly enabled.

The completed phase is persisted before a new phase starts. A failed database save prevents progression. Each phase has its own session ID, segments and notification ID. Starting the break cannot replace the just-completed focus notification. Optional focus reflection refers to the completed focus ID even when an automatic break starts. After a break, automatic focus reuses the latest non-deleted completed focus context and configured focus duration.

Tempo does not synthesize a chain of unattended sessions for time spent terminated or offline. Notification delivery and actual macOS sleep/wake still require platform verification.

## Tests and remaining work

SessionWorkflowTests verifies per-project/task time after switching, paused switches, legacy context preservation, interruption behavior, cycle opt-in/end-of-cycle rules, expired-edit rejection and JSON round trips. Existing timing/browser tests remain in place. Direct AppStore orchestration, editor keyboard/accessibility flows and automated notification delivery remain native validation gates.
