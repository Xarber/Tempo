# Architecture

Tempo has a dependency-free Swift package with a system SQLite module, portable TempoCore library, and macOS Tempo executable. macOS 14 is the declared minimum. Swift 6 concurrency checking is enabled by the package tools version.

TempoCore owns value models, timer transitions, interval calculations, archive validation and portability. TimerEngine receives wall and monotonic samples explicitly, allowing deterministic edge tests. UI never decrements persisted seconds. SwiftUI AppStore is main-actor isolated and coordinates commands, transactional persistence, completion scheduling and notifications. Menu bar, main window and floating panel share this single store; closing a window does not end the app.

SQLite stores a validated versioned snapshot of the complete object graph in one transaction with WAL and FULL synchronization. This intentionally simple first schema provides crash atomicity without a third-party wrapper. It is not a normalized analytics database and scales by decoding all records; large-history optimization remains necessary. UserDefaults is not used for history.

Platform mechanisms: MenuBarExtra, AppKit floating window level, NSWorkspace activation reminders, UserNotifications, ServiceManagement. No elevated privileges, Accessibility or Automation permission is requested. No application is forcibly hidden or terminated.

Extension seams are public core value types, portability APIs and a separate command coordinator. A plugin permission/runtime registry is not implemented. Never describe these seams as a functioning plugin runtime.

Optional browser companion uses an expiring browser-state.json policy file and a read-only Native Messaging host; the extension installs only browser session rules. No generic remote commands are exposed. See BROWSER_EXTENSION.md.

No server, account system, iOS app target or web application is implemented yet. Do not add placeholder screens claiming otherwise.
