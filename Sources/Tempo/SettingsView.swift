// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import TempoCore
import ServiceManagement

struct SettingsView: View {
    @Bindable var store: AppStore
    @State private var appID = ""
    @State private var loginError: String?
    @State private var menuOnly = false
    private func binding<T>(_ key: WritableKeyPath<TempoCore.Settings,T>) -> Binding<T> { Binding(get: { store.archive.settings[keyPath: key] }, set: { value in store.update { $0.settings[keyPath: key] = value } }) }
    var body: some View { Form {
        Section { PageHeader(title: "Settings", subtitle: "A focus practice that fits you.") }
        Section("Timer & reflection") {
            Toggle("Minimal digital timer", isOn: binding(\.digitalTimer))
            Toggle("Offer an optional reflection", isOn: binding(\.reflectionPrompts))
            Stepper("Daily goal: \(store.archive.settings.dailyGoal) minutes", value: binding(\.dailyGoal), in: 1...1440, step: 15)
            HStack { Text("Preset: \(store.minutes) minutes"); Button("Save current duration") { store.update { a in if !a.settings.presets.contains(store.minutes) { a.settings.presets.append(store.minutes); a.settings.presets.sort() } } }.disabled(store.archive.settings.presets.count >= 10) }
        }
        Section("Focus / break cycle") {
            Toggle("Show cycle guidance", isOn: binding(\.cycle.enabled))
            Stepper("Focus: \(Int(store.archive.settings.cycle.focus / 60)) min", value: binding(\.cycle.focus), in: 60...86400, step: 60)
            Stepper("Short break: \(Int(store.archive.settings.cycle.shortBreak / 60)) min", value: binding(\.cycle.shortBreak), in: 60...86400, step: 60)
            Stepper("Long break: \(Int(store.archive.settings.cycle.longBreak / 60)) min", value: binding(\.cycle.longBreak), in: 60...86400, step: 60)
            Stepper("Long break after \(store.archive.settings.cycle.count) sessions", value: binding(\.cycle.count), in: 1...24)
            Button("Use cycle focus duration") { store.minutes = Int(store.archive.settings.cycle.focus / 60); store.kind = .focus }
            Toggle("Start breaks automatically at the deadline", isOn: Binding(get: { store.archive.settings.cycle.automaticBreaks ?? false }, set: { value in store.update { $0.settings.cycle.automaticBreaks = value } }))
            Toggle("Start next focus automatically after a break", isOn: Binding(get: { store.archive.settings.cycle.automaticFocus ?? false }, set: { value in store.update { $0.settings.cycle.automaticFocus = value } }))
            Toggle("Continue automatically after long breaks", isOn: Binding(get: { store.archive.settings.cycle.continueAfterLongBreak ?? false }, set: { value in store.update { $0.settings.cycle.continueAfterLongBreak = value } }))
            Button("Reset cycle progress") { store.update { $0.settings.cycle.completed = 0 } }
            Text("Automatic progression is optional and happens only at natural deadlines while Tempo is running. Finishing early, abandoning, restarting the app, or disabling cycle guidance does not start another phase.").font(.caption).foregroundStyle(.secondary)
        }
        Section("Notifications & privacy") {
            if store.archive.settings.notifications { Toggle("Session completion notifications", isOn: binding(\.notifications)) } else { Button("Enable completion notifications…") { store.enableNotifications() } }
            Text("Notifications use a generic preview. No task names, analytics, or activity records leave this device.").font(.caption).foregroundStyle(.secondary)
        }
        Section("macOS") {
            Toggle("Menu bar only (hide Dock icon)", isOn: $menuOnly).onChange(of: menuOnly) { _, hidden in NSApp.setActivationPolicy(hidden ? .accessory : .regular) }
            Button("Enable launch at login") { do { try SMAppService.mainApp.register() } catch { loginError = error.localizedDescription } }
            Button("Disable launch at login") { Task { do { try await SMAppService.mainApp.unregister() } catch { loginError = error.localizedDescription } } }
            if let loginError { Text(loginError).font(.caption).foregroundStyle(.orange) }
        }
        Section("Distraction reminders · local only") {
            Toggle("Warn when a configured application becomes active", isOn: binding(\.distractionEnabled))
            HStack { TextField("Application bundle ID (e.g. com.example.app)", text: $appID); Button("Add") { let value = appID.trimmingCharacters(in: .whitespacesAndNewlines); guard value.contains("."), !store.archive.settings.distractingApps.contains(value) else { return }; store.update { $0.settings.distractingApps.append(value) }; appID = "" } }
            ForEach(store.archive.settings.distractingApps, id: \.self) { id in HStack { Text(id); Spacer(); Button("Remove") { store.update { $0.settings.distractingApps.removeAll { $0 == id } } } } }
            DisclosureGroup("Capabilities and permissions") { Text("Uses NSWorkspace activation events only while configured focus is running. No window titles, keystrokes, forced termination, or permanent restrictions. Website rules require the optional browser extension below. iOS Screen Time controls are not implemented.").font(.caption) }
        }
        DistractionSettingsView(store: store)
        Section("Your data") {
            HStack { Button("Export JSON…") { store.exportData("json") }; Button("Import & review…") { store.previewImport() } }
            Text("Imports merge new IDs after review. Existing records and preferences are preserved. Deleted sessions remain recoverable in History.").font(.caption).foregroundStyle(.secondary)
        }
        Section("What's new") {
            Label("0.1.0 · Local foundations", systemImage: "sparkles")
            Text("Focus and break timers, menu bar, projects, tasks, reflection and measured-time analytics.").font(.caption)
            DisclosureGroup("Fixes & Improvements / Technical details") { Text("Transactional SQLite persistence; continuous clock timing; explicit recovery estimates; validated portable data. This is the first development version. No public releases or automatic update endpoint exist yet.").font(.caption) }
        }
        Section {
            Button("Tempo 0.1.0 · Developer access") { store.versionTap() }.buttonStyle(.plain)
            if store.developerVisible { NavigationLink("Developer Options & Ideas") { DeveloperView(store: store) } }
            Text("OpenRecode · AGPL-3.0-only · Offline by default").font(.caption2).foregroundStyle(.secondary)
        }
    }.formStyle(.grouped) }
}
struct DeveloperView: View {
    @Bindable var store: AppStore
    @State private var title = ""
    @State private var search = ""
    @State private var filter = "All"
    var body: some View {
        if store.developerVisible {
            ScrollView { VStack(alignment: .leading, spacing: 20) {
                PageHeader(title: "Developer Options", subtitle: "Sanitized local diagnostics and private ideas.")
                GroupBox("Diagnostics") { VStack(alignment: .leading, spacing: 7) {
                    Text("Tempo 0.1.0 · build \(Bundle.main.object(forInfoDictionaryKey: "TempoCommit") as? String ?? "development")")
                    Text("SQLite schema 1 · Timer: \(store.current?.status.rawValue ?? "idle") · Revision \(store.current?.revision ?? 0)")
                    Text("Continuous clock: active · Sync: disabled · Pending sync: 0")
                    Text("Calendar / Live Activities: unavailable · Browser connection: not verified")
                }.font(.caption).frame(maxWidth: .infinity, alignment: .leading) }
                Text("Ideas").font(.title2)
                HStack { TextField("New idea title", text: $title); Button("Add") { store.update { $0.ideas.append(Idea(title: title)) }; title = ""; store.touchDeveloper() }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                HStack { TextField("Search ideas", text: $search); Picker("Status", selection: $filter) { ForEach(["All","Pending","Approved","Deferred","In Progress","Implemented","Rejected"], id: \.self) { Text($0).tag($0) } } }
                ForEach(store.archive.ideas.filter { (filter == "All" || $0.status == filter) && (search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) || $0.detail.localizedCaseInsensitiveContains(search)) }.sorted { $0.modified > $1.modified }) { idea in
                    IdeaEditor(store: store, idea: idea)
                }
                Text("Ideas are private and local. Export JSON includes them; import previews and preserves existing IDs. Codex can read them only after an authorized export into docs/IDEAS.json.").font(.caption).foregroundStyle(.secondary)
                HStack { Button("Export data including Ideas") { store.exportData("json"); store.touchDeveloper() }; Button("Import & review") { store.previewImport(); store.touchDeveloper() } }
            }.padding(30) }.onTapGesture { store.touchDeveloper() }
        } else { ContentUnavailableView("Developer access expired", systemImage: "lock", description: Text("Tap the version three times in Settings to reopen.")) }
    }
}
struct IdeaEditor: View {
    @Bindable var store: AppStore
    var idea: Idea
    private func binding(_ key: WritableKeyPath<Idea,String>) -> Binding<String> { Binding(get: { store.archive.ideas.first(where: { $0.id == idea.id })?[keyPath: key] ?? "" }, set: { value in store.update { a in if let i = a.ideas.firstIndex(where: { $0.id == idea.id }) { a.ideas[i][keyPath: key] = value; a.ideas[i].modified = Date() } }; store.touchDeveloper() }) }
    var body: some View { DisclosureGroup {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Title", text: binding(\.title)); TextField("Description", text: binding(\.detail), axis: .vertical)
            Picker("Category", selection: binding(\.category)) { ForEach(["Feature","Improvement","Bug Fix","UI/UX","Performance","Other"], id: \.self) { Text($0).tag($0) } }
            Picker("Priority", selection: binding(\.priority)) { ForEach(["Low","Normal","High"], id: \.self) { Text($0).tag($0) } }
            Picker("Status", selection: binding(\.status)) { ForEach(["Pending","Approved","Deferred","In Progress","Implemented","Rejected"], id: \.self) { Text($0).tag($0) } }
            TextField("Implementation / changelog references", text: binding(\.implementation))
            Text("Created \(idea.created.formatted()) · Modified \(idea.modified.formatted())").font(.caption).foregroundStyle(.secondary)
            HStack { Button("Duplicate") { store.update { a in var copy = idea; copy.id = UUID(); copy.created = Date(); copy.modified = Date(); a.ideas.append(copy) } }; Button("Copy") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString("\(idea.title)\n\(idea.detail)", forType: .string) }; Button("Delete", role: .destructive) { store.update { $0.ideas.removeAll { $0.id == idea.id } } } }
        }.padding(.vertical, 12)
    } label: { Label("\(idea.title) · \(idea.status)", systemImage: "lightbulb") }.padding(16).background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12)) }
}
