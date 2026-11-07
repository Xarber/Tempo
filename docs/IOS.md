# iOS / iPadOS status

Not implemented. TempoCore declares iOS 17 support as a portability target, but the executable imports AppKit and is macOS-only. A declared library deployment target is not an iOS app.

Next steps: native app target with shared core, app-group persistence, notification reconciliation, App Intents, WidgetKit and ActivityKit extension targets. ActivityKit availability and supported controls must be checked against the actual deployment SDK. Real-device signing, provisioning, Live Activity settings and privacy-friendly content need physical validation.

Screen Time controls require FamilyControls capability, authorization and Apple's distribution entitlement approval. Timer functionality must remain independent. See Apple's official Family Controls and entitlement documentation; do not enable restricted entitlements before configuration and authorization.
