# Distraction management

Implemented subset: explicitly enabled local NSWorkspace activation reminders for user-entered bundle IDs, only while a focus session runs. No activation history or window titles are stored. Reminder does not forcibly hide/quit apps or require Accessibility. Disabling this setting ends monitoring responses. Since no persistent restrictions are applied, crash recovery cannot leave the system blocked.

Additional implemented source: saved distraction profiles, domain rules, Chromium companion extension, read-only native messaging bridge and temporary website-rule pause. See BROWSER_EXTENSION.md for setup and validation limits. Browser installation/navigation has not been verified. Not implemented: allowlists, scheduled restrictions, Safari/Firefox extensions and iOS Screen Time. Do not market a reminder as enforced application blocking. Supported future browser extensions should use documented browser APIs and session-limited, recoverable rules. Never edit hosts files or inject browser processes.

Official platform references: https://developer.apple.com/documentation/appkit/nsworkspace and https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement .
