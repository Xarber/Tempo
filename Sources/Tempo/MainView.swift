// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import Charts
import TempoCore

struct MainView: View {
    @Bindable var store: AppStore
    @State private var section = "Focus"
    @Environment(\.openWindow) private var open
    private let sections = [("Focus","circle.lefthalf.filled"),("Projects","square.stack.3d.up"),("Tasks","checklist"),("History","clock.arrow.circlepath"),("Analytics","chart.bar.xaxis"),("Settings","gearshape")]
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) { Image(systemName: "circle.lefthalf.filled").foregroundStyle(tempoAccent).font(.title); Text("Tempo").font(.title2.weight(.semibold)) }.padding(.bottom, 26).padding(.top, 22)
                ForEach(sections, id: \.0) { name, icon in
                    Button { section = name } label: { HStack { Label(name, systemImage: icon); Spacer() }.padding(11).contentShape(Rectangle()) }
                        .buttonStyle(.plain).background(section == name ? tempoAccent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 9)).foregroundStyle(section == name ? tempoAccent : .primary)
                }
                if store.developerVisible { Button { section = "Developer"; store.touchDeveloper() } label: { Label("Developer", systemImage: "hammer").padding(11) }.buttonStyle(.plain) }
                Spacer()
                VStack(alignment: .leading, spacing: 8) { Text("A little space to focus.").font(.caption).foregroundStyle(.secondary); Text(store.isQA ? "OpenRecode · QA data only" : "OpenRecode").font(.caption2).foregroundStyle(.tertiary) }.padding(10)
            }.padding(.horizontal, 14).navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 250)
        } detail: {
            Group {
                switch section {
                case "Projects": ProjectsView(store: store)
                case "Tasks": TasksView(store: store)
                case "History": HistoryView(store: store)
                case "Analytics": AnalyticsView(store: store)
                case "Settings": SettingsView(store: store)
                case "Developer": if store.developerVisible { DeveloperView(store: store) } else { SettingsView(store: store) }
                default: FocusView(store: store)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(nsColor: .windowBackgroundColor))
        }
        .toolbar { ToolbarItem { Button("Floating timer", systemImage: "pip") { open(id: "floating") } } }
        .onChange(of: section) { _, _ in if section != "Developer" { store.developerUntil = nil; store.versionTaps = 0 } }
        .alert("Tempo needs attention", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) { Button("OK") { store.error = nil } } message: { Text(store.error ?? "") }
        .alert("Return to your intention", isPresented: Binding(get: { store.blockingReminder != nil }, set: { if !$0 { store.blockingReminder = nil } })) { Button("Continue focusing") { store.blockingReminder = nil } } message: { Text(store.blockingReminder ?? "") }
        .sheet(isPresented: Binding(get: { store.reflectionID != nil }, set: { if !$0 { store.reflectionID = nil } })) { if let id = store.reflectionID { ReflectionView(store: store, id: id) } }
        .sheet(isPresented: $store.editingContext) { SessionContextEditor(store: store) }
        .sheet(isPresented: $store.recordingInterruption) { InterruptionEditor(store: store) }
        .sheet(isPresented: Binding(get: { store.importPreview != nil }, set: { if !$0 { store.importPreview = nil } })) { VStack(alignment: .leading, spacing: 20) { Text("Review import").font(.title2); Text(store.importSummary); HStack { Button("Cancel") { store.importPreview = nil }; Spacer(); Button("Merge new records") { store.applyImport() }.buttonStyle(.borderedProminent) } }.padding(30).frame(width: 480) }
    }
}
struct PageHeader: View {
    var title: String; var subtitle: String
    var body: some View { VStack(alignment: .leading, spacing: 7) { Text(title).font(.system(size: 30, weight: .semibold, design: .rounded)); Text(subtitle).font(.callout).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading) }
}
struct FocusView: View {
    @Bindable var store: AppStore
    var progress: Double { guard let s = store.current, let planned = s.planned else { return 0 }; return min(1, s.active / planned) }
    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                HStack { PageHeader(title: "Make room for focus.", subtitle: "One intention. A little uninterrupted time."); Spacer(); Label("Local · Offline ready", systemImage: "internaldrive").font(.caption).foregroundStyle(.secondary) }
                if !store.recovery.isEmpty { Label(store.recovery, systemImage: "clock.badge.exclamationmark").font(.caption).padding(12).background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10)) }
                Spacer(minLength: 6)
                ZStack {
                    if !store.archive.settings.digitalTimer {
                        Circle().stroke(tempoAccent.opacity(0.09), lineWidth: 9)
                        Circle().trim(from: 0, to: store.isActive ? max(0.003, 1 - progress) : 1).stroke(tempoAccent.gradient, style: StrokeStyle(lineWidth: 9, lineCap: .round)).rotationEffect(.degrees(-90))
                    }
                    VStack(spacing: 12) {
                        Text(store.isActive ? store.current!.kind.label.uppercased() : "YOUR NEXT SESSION").font(.caption.weight(.medium)).tracking(2).foregroundStyle(.secondary)
                        Text(store.timeText).font(.system(size: 66, weight: .light, design: .rounded)).monospacedDigit().contentTransition(.identity).accessibilityLabel("Timer \(store.timeText)")
                        Text(store.current?.status == .paused ? "Paused · take your time" : store.isActive ? "Stay with what matters." : "Ready when you are.").font(.callout).foregroundStyle(.secondary)
                    }
                }.frame(width: 290, height: 290).padding(.vertical, 6)
                if store.isActive {
                    Text(store.current?.intention.isEmpty == false ? store.current!.intention : "A moment of focused work").font(.title3).multilineTextAlignment(.center)
                    HStack(spacing: 12) {
                        Button(store.current?.status == .paused ? "Resume" : "Pause", systemImage: store.current?.status == .paused ? "play.fill" : "pause.fill") { store.pauseResume() }.buttonStyle(.borderedProminent)
                        Button("Finish", systemImage: "checkmark") { store.finish() }.buttonStyle(.bordered)
                        Menu { Button("Edit intention or switch task") { store.editingContext = true }; Button("Record interruption") { store.recordingInterruption = true }; Button("Add 5 minutes") { store.adjust(300) }; Button("Reduce by 5 minutes") { store.adjust(-300) }; Button("Restart") { store.restart() }; Button("Abandon session", role: .destructive) { store.finish(abandon: true) } } label: { Image(systemName: "ellipsis") }.menuStyle(.borderlessButton).frame(width: 30)
                    }.controlSize(.large)
                } else {
                    VStack(spacing: 14) {
                        TextField("What would you like to focus on?", text: $store.intention).textFieldStyle(.plain).font(.title3).padding(16).background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                        HStack {
                            Picker("Project", selection: $store.projectID) { Text("No project").tag(nil as UUID?); ForEach(store.archive.projects.filter { $0.status != "Archived" }) { Text($0.name).tag(Optional($0.id)) } }.labelsHidden().frame(maxWidth: .infinity)
                            Picker("Session", selection: $store.kind) { ForEach(SessionKind.allCases, id: \.self) { Text($0.label).tag($0) } }.labelsHidden().frame(maxWidth: .infinity)
                        }
                        HStack(spacing: 8) { ForEach(store.archive.settings.presets, id: \.self) { value in Button("\(value)m") { store.minutes = value }.buttonStyle(.bordered).tint(store.minutes == value ? tempoAccent : .secondary) }; TextField("Minutes", value: $store.minutes, format: .number).frame(width: 45).textFieldStyle(.roundedBorder).accessibilityLabel("Custom duration in minutes") }
                        Button { store.start() } label: { Label("Start session", systemImage: "play.fill").frame(maxWidth: .infinity).padding(7) }.buttonStyle(.borderedProminent).controlSize(.large).keyboardShortcut(.return, modifiers: .command)
                        if store.current?.status == .completed { Button("Take a restorative break", systemImage: "cup.and.saucer") { store.startBreak() }.buttonStyle(.plain).foregroundStyle(tempoAccent) }
                    }.frame(maxWidth: 520)
                }
                Spacer(minLength: 6)
                HStack(spacing: 32) {
                    VStack(spacing: 5) { Text("\(Int(store.today / 60)) min").font(.headline); Text("Focused today").font(.caption).foregroundStyle(.secondary) }
                    Divider().frame(height: 30)
                    VStack(spacing: 5) { Text("\(store.archive.settings.cycle.completed) sessions").font(.headline); Text(store.archive.settings.cycle.enabled ? "Next: \(store.archive.settings.cycle.nextBreak.label.lowercased())" : "At your own pace").font(.caption).foregroundStyle(.secondary) }
                }.padding(20).frame(maxWidth: 520).background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
            }.padding(36).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.onChange(of: store.projectID) { _, _ in if !store.isActive { store.taskID = nil } }
    }
}
struct ProjectsView: View {
    @Bindable var store: AppStore
    @State private var name = ""
    @State private var editing: Project?
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 24) {
        PageHeader(title: "Projects", subtitle: "Give your time a meaningful home.")
        HStack { TextField("New project name", text: $name); Button("Create", systemImage: "plus") { let clean = name.trimmingCharacters(in: .whitespacesAndNewlines); guard !clean.isEmpty else { return }; store.update { $0.projects.append(Project(name: clean)) }; name = "" }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        if store.archive.projects.isEmpty { ContentUnavailableView("A fresh start", systemImage: "square.stack.3d.up", description: Text("Create a project to see its tasks and recorded focus time here.")) }
        ForEach(store.archive.projects) { project in
            VStack(alignment: .leading, spacing: 12) {
                HStack { Image(systemName: "square.stack.3d.up.fill").foregroundStyle(tempoAccent); Text(project.name).font(.headline); Spacer(); Text(project.status).foregroundStyle(.secondary) }
                Text("\(Int(Analytics.projectSeconds(project.id, sessions: store.archive.sessions) / 60)) minutes recorded · \(store.archive.tasks.filter { $0.projectID == project.id && !$0.complete }.count) open tasks").foregroundStyle(.secondary)
                HStack { Button("Focus on project", systemImage: "play") { store.projectID = project.id; store.taskID = nil; store.intention = project.name; store.kind = .focus; store.start() }.disabled(store.isActive)
                    Button("Edit", systemImage: "pencil") { editing = project }
                    Menu("Status") { ForEach(["Planned","Active","Paused","Completed","Archived"], id: \.self) { status in Button(status) { store.update { a in if let i = a.projects.firstIndex(where: { $0.id == project.id }) { a.projects[i].status = status } } } } }
                }
            }.padding(20).background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 14))
        }
    }.padding(36) }.sheet(item: $editing) { project in ProjectEditor(store: store, project: project) } }
}
struct TasksView: View {
    @Bindable var store: AppStore
    @State private var title = ""
    @State private var project: UUID?
    @State private var editing: WorkTask?
    var body: some View { VStack(alignment: .leading, spacing: 24) {
        PageHeader(title: "Tasks", subtitle: "Small steps toward meaningful work.")
        HStack { TextField("Add a task", text: $title); Picker("Project", selection: $project) { Text("None").tag(nil as UUID?); ForEach(store.archive.projects) { Text($0.name).tag(Optional($0.id)) } }.frame(width: 200); Button("Add") { store.update { $0.tasks.append(WorkTask(title: title, projectID: project)) }; title = "" }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        if store.archive.tasks.isEmpty { ContentUnavailableView("Nothing on your list", systemImage: "checklist", description: Text("Add a task, or start a focus session without one.")) }
        List { ForEach(store.archive.tasks) { task in HStack(spacing: 14) {
            Button { store.update { a in if let i = a.tasks.firstIndex(where: { $0.id == task.id }) { a.tasks[i].complete.toggle() } } } label: { Image(systemName: task.complete ? "checkmark.circle.fill" : "circle").font(.title3) }.buttonStyle(.plain).accessibilityLabel(task.complete ? "Reopen task" : "Complete task")
            VStack(alignment: .leading) { Text(task.title).strikethrough(task.complete); Text("\(Int(Analytics.taskSeconds(task.id, sessions: store.archive.sessions) / 60)) minutes focused").font(.caption).foregroundStyle(.secondary) }; Spacer()
            Button("Edit", systemImage: "pencil") { editing = task }; Button("Focus", systemImage: "play.fill") { store.focusTask(task) }.disabled(store.isActive)
        }.padding(.vertical, 10) } }.listStyle(.inset)
    }.padding(36).sheet(item: $editing) { task in TaskEditor(store: store, task: task) } }
}
struct ReflectionView: View {
    @Bindable var store: AppStore
    let id: UUID
    @State private var note = ""
    @State private var rating = 3
    var body: some View { VStack(alignment: .leading, spacing: 20) {
        Image(systemName: "leaf").font(.largeTitle).foregroundStyle(tempoAccent)
        Text("A moment to reflect").font(.title2.weight(.semibold)); Text("What did you accomplish? This is entirely optional.").foregroundStyle(.secondary)
        TextEditor(text: $note).frame(height: 120).border(.quaternary)
        Picker("How focused did you feel?", selection: $rating) { ForEach(1...5, id: \.self) { Text("\($0)").tag($0) } }.pickerStyle(.segmented)
        Text("A personal assessment, rather than a measured score.").font(.caption).foregroundStyle(.secondary)
        HStack { Button("Skip") { store.reflectionID = nil }; Spacer(); Button("Save reflection") { store.saveReflection(id: id, note: note, rating: rating) }.buttonStyle(.borderedProminent) }
    }.padding(30).frame(width: 460).onAppear { if let s = store.archive.sessions.first(where: { $0.id == id }) { note = s.reflection; rating = s.rating ?? 3 } } }
}
struct HistoryView: View {
    @Bindable var store: AppStore
    @State private var search = ""
    @State private var showTrash = false
    var body: some View { VStack(alignment: .leading, spacing: 20) {
        PageHeader(title: "History", subtitle: "An honest record of your time, including breaks.")
        HStack { TextField("Search intentions", text: $search); Toggle("Recently deleted", isOn: $showTrash).toggleStyle(.switch) }
        List { ForEach(store.archive.sessions.filter { !$0.isActive && ($0.deletedAt != nil) == showTrash && (search.isEmpty || $0.intention.localizedCaseInsensitiveContains(search)) }.sorted { $0.started > $1.started }) { session in
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Planned: \(session.planned.map { AppStore.format($0) } ?? "Open ended") · Active: \(AppStore.format(session.active)) · Paused: \(AppStore.format(session.paused))").font(.caption)
                    if let note = session.recoveryNote { Label(note, systemImage: "exclamationmark.circle").font(.caption).foregroundStyle(.orange) }
                    if !session.reflection.isEmpty { Text(session.reflection) }
                    if let changes = session.contextRevisions, !changes.isEmpty { Text("Context changes: \(changes.count) · Historical segment attribution preserved").font(.caption) }
                    ForEach(session.interruptions ?? []) { interruption in
                        Label("\(interruption.category.rawValue) · \(interruption.at.formatted(date: .omitted, time: .shortened))\(interruption.pausedSession ? " · paused" : "")\(interruption.note.isEmpty ? "" : " — " + interruption.note)", systemImage: "pause.circle").font(.caption)
                    }
                    HStack {
                        Button("Reflection", systemImage: "text.bubble") { store.reflectionID = session.id }
                        if showTrash { Button("Restore") { store.update { a in if let i = a.sessions.firstIndex(where: { $0.id == session.id }) { a.sessions[i].deletedAt = nil } } } }
                        else { Button("Move to recently deleted", role: .destructive) { store.update { a in if let i = a.sessions.firstIndex(where: { $0.id == session.id }) { a.sessions[i].deletedAt = Date() } } } }
                    }
                }.padding(.vertical, 10)
            } label: {
                HStack(spacing: 14) { Image(systemName: session.kind.isFocus ? "circle.lefthalf.filled" : "cup.and.saucer").foregroundStyle(tempoAccent)
                    VStack(alignment: .leading, spacing: 4) { Text(session.intention.isEmpty ? session.kind.label : session.intention).font(.headline); Text(session.started.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary) }
                    Spacer(); VStack(alignment: .trailing) { Text(AppStore.format(session.active)).monospacedDigit(); Text(session.status.rawValue.capitalized).font(.caption).foregroundStyle(.secondary) }
                }.padding(.vertical, 8)
            }
        } }.listStyle(.inset)
        HStack { Button("Export JSON") { store.exportData("json") }; Button("Export CSV") { store.exportData("csv") }; Button("Markdown report") { store.exportData("md") }; Spacer(); Button("Import…") { store.previewImport() } }
    }.padding(36) }
}
struct AnalyticsView: View {
    @Bindable var store: AppStore
    @State private var range = 7
    var days: [DailyTotal] { Analytics.days(store.archive.sessions, ending: store.now, count: range) }
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 28) {
        PageHeader(title: "Your time, understood.", subtitle: "Recorded focus time. Pauses and breaks excluded.")
        Picker("Range", selection: $range) { Text("Week").tag(7); Text("Month").tag(30); Text("Year").tag(365) }.pickerStyle(.segmented).frame(width: 300)
        HStack(spacing: 40) { metric("\(Int(days.reduce(0) { $0 + $1.seconds } / 60))", label: "Minutes in this period"); metric("\(store.history.filter { $0.status == .completed && $0.kind.isFocus }.count)", label: "Completed focus sessions · all time"); metric("\(Int(store.today / 60)) / \(store.archive.settings.dailyGoal)", label: "Today's optional goal · minutes") }
        Chart(days) { day in BarMark(x: .value("Day", day.date, unit: .day), y: .value("Focus minutes", day.seconds / 60)).foregroundStyle(tempoAccent.gradient).cornerRadius(4) }.chartYAxisLabel("Minutes").chartYScale(domain: .automatic(includesZero: true)).frame(height: 240)
        Text("Time by project · all time").font(.headline)
        ForEach(store.archive.projects) { project in let total = Analytics.projectSeconds(project.id, sessions: store.archive.sessions)
            HStack { Label(project.name, systemImage: "square.stack.3d.up"); Spacer(); Text("\(Int(total / 60)) min").monospacedDigit() }.padding(14).background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
        }
        if store.history.isEmpty { ContentUnavailableView("Your story starts here", systemImage: "chart.bar", description: Text("Complete a focus session to build a picture of your working rhythm. No sample data is included.")) }
        Text("Timer-recorded elapsed durations are measured. Durations recovered across process restarts are estimated and labelled in history. Ratings are self-reported.").font(.caption).foregroundStyle(.secondary)
    }.padding(36) } }
    func metric(_ value: String, label: String) -> some View { VStack(alignment: .leading, spacing: 8) { Text(value).font(.system(size: 30, weight: .medium, design: .rounded)); Text(label).font(.caption).foregroundStyle(.secondary) } }
}
