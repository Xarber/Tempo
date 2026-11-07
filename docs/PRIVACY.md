# Privacy

Local-only by default and in this build. No analytics telemetry, trackers, ad SDKs, account, hidden application monitoring, window title collection, keystroke logging or screen capture. Optional app reminders inspect foreground bundle IDs transiently after opt-in; do not store activation history.

SQLite has restricted local permissions and no application encryption. Operating-system user access controls and optional FileVault protect disk access. Optional browser integration shares only configured domains, opaque session ID and short expiry with a user-installed local extension. It does not transmit private task names or activity records.

Files exported by the user contain private data and should be stored securely. No E2EE claim is made. There are no server retention or account deletion mechanisms because no service exists.

Session deletion is recoverable soft deletion. Permanent deletion, project deletion, whole-history clearing and encrypted export are not implemented; do not claim a UI control exists for them. Developer diagnostics avoid intentions, tokens and activity logs. Developer Ideas stay local until deliberate export.
