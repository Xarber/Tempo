// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import AppKit
import TempoCore
import UserNotifications

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) { UNUserNotificationCenter.current().delegate = self }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions { [.banner, .sound] }
    var onTerminate: (() -> Void)?
    func applicationWillTerminate(_ notification: Notification) { onTerminate?() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
@main struct TempoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var store = AppStore()
    var body: some Scene {
        Window("Tempo", id: "main") { MainView(store: store).onAppear { delegate.onTerminate = { store.flush() } }.frame(minWidth: 850, minHeight: 640).tint(tempoAccent) }
            .defaultSize(width: 1100, height: 760)
            .commands { CommandGroup(after: .newItem) { Button("Start Focus") { store.start() }.keyboardShortcut("n", modifiers: [.command,.shift]); Button("Pause / Resume") { store.pauseResume() }.keyboardShortcut("p", modifiers: [.command,.shift]).disabled(!store.isActive) } }
        MenuBarExtra { MenuView(store: store).tint(tempoAccent) } label: {
            Label(store.isActive ? store.timeText : "Tempo", systemImage: store.current?.status == .paused ? "pause.circle" : "circle.lefthalf.filled")
        }.menuBarExtraStyle(.window)
        Window("Floating Timer", id: "floating") { FloatingView(store: store).frame(width: 280, height: 170).background(WindowAccessor()) }.windowResizability(.contentSize).defaultPosition(.topTrailing)
        Settings { SettingsView(store: store).frame(width: 580, height: 650).padding().tint(tempoAccent) }
    }
}
let tempoAccent = Color(red: 98/255, green: 105/255, blue: 245/255)
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { let view = NSView(); DispatchQueue.main.async { view.window?.level = .floating; view.window?.isMovableByWindowBackground = true; view.window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary] }; return view }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
struct FloatingView: View {
    @Bindable var store: AppStore
    @Environment(\.dismissWindow) private var dismiss
    var body: some View { VStack(spacing: 14) {
        Text(store.current?.intention.isEmpty == false ? store.current!.intention : "Make time for what matters").font(.caption).lineLimit(1)
        Text(store.timeText).font(.system(size: 38, weight: .light, design: .rounded)).monospacedDigit().accessibilityLabel("Timer \(store.timeText)")
        HStack { Button(store.current?.status == .paused ? "Resume" : "Pause", systemImage: store.current?.status == .paused ? "play.fill" : "pause.fill") { store.pauseResume() }.disabled(!store.isActive); Button("Hide", systemImage: "xmark") { dismiss(id: "floating") } }
    }.padding(20).background(.regularMaterial) }
}
struct MenuView: View {
    @Bindable var store: AppStore
    @Environment(\.openWindow) private var open
    var body: some View { VStack(alignment: .leading, spacing: 18) {
        HStack { Label("Tempo", systemImage: "circle.lefthalf.filled").font(.headline); Spacer(); Text(store.current?.status.rawValue.capitalized ?? "Ready").foregroundStyle(.secondary) }
        Text(store.current?.intention.isEmpty == false ? store.current!.intention : "Make time for what matters.").lineLimit(2)
        Text(store.timeText).font(.system(size: 48, weight: .light, design: .rounded)).monospacedDigit()
        if store.isActive { HStack { Button(store.current?.status == .paused ? "Resume" : "Pause") { store.pauseResume() }; Button("Finish") { store.finish() } }; Button("Extend 5 minutes") { store.adjust(300) } }
        else { HStack { ForEach([25,45,90], id: \.self) { minute in Button("\(minute)m") { store.kind = .focus; store.minutes = minute; store.start() } } }; Button("Take a break", systemImage: "cup.and.saucer") { store.startBreak() } }
        Divider()
        Button("Open Tempo", systemImage: "macwindow") { open(id: "main"); NSApp.activate(ignoringOtherApps: true) }
        Button("Floating timer", systemImage: "pip") { open(id: "floating") }
        SettingsLink { Label("Settings", systemImage: "gearshape") }
        Button("Quit Tempo") { store.flush(); NSApp.terminate(nil) }
    }.padding(22).frame(width: 300) }
}
