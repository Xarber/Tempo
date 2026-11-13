# iOS / iPadOS status

The Expo React Native companion opens directly to the timer and supports focus, breaks, pause, resume, finish and recent sessions using SQLite. The iOS production JavaScript export succeeds. App installation and SQLite runtime behavior still need simulator and physical-device testing. The Swift executable remains macOS-only.

Next steps: validated device build, app-group persistence, notification reconciliation, App Intents, WidgetKit and ActivityKit extension targets. ActivityKit availability and supported controls must be checked against the actual deployment SDK. Real-device signing, provisioning, Live Activity settings and privacy-friendly content need physical validation.

Screen Time controls require FamilyControls capability, authorization and Apple's distribution entitlement approval. Timer functionality must remain independent. See Apple's official Family Controls and entitlement documentation; do not enable restricted entitlements before configuration and authorization.
