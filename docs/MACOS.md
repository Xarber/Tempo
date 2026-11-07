# macOS behavior

SwiftUI main window, MenuBarExtra window-style popover and AppKit-level floating timer share one authoritative store. Last-window closure does not quit. Popover supports presets, pause/resume, finish, extension, break, full window, settings and explicit Quit. Floating timer joins spaces and floats above normal windows; it can be dragged by background.

Settings expose a temporary Dock/accessory toggle and SMAppService login registration. Those operating-system behaviors need installation-path and permission testing. Multiple-display positioning, actual sleep/wake, VoiceOver and reduced-transparency/high-contrast review remain validation gates.

Notification permission is requested only on explicit enable. Completion requests use privacy-friendly generic text and stable ID to replace outdated pending requests. Delivery is subject to operating-system permissions and scheduling. No guarantee of exact audible delivery is made.
