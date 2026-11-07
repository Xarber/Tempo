// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import TempoCore

struct ProjectEditor: View {
    @Bindable var store: AppStore
    @State var project: Project
    @Environment(\.dismiss) private var dismiss
    var body: some View { VStack(alignment: .leading, spacing: 18) {
        Text("Edit project").font(.title2)
        TextField("Name", text: $project.name)
        TextField("Description", text: $project.notes, axis: .vertical).lineLimit(3...6)
        Picker("Status", selection: $project.status) { ForEach(["Planned","Active","Paused","Completed","Archived"], id: \.self) { Text($0).tag($0) } }
        HStack { Button("Cancel") { dismiss() }; Spacer(); Button("Save") { store.update { a in if let i = a.projects.firstIndex(where: { $0.id == project.id }) { a.projects[i] = project } }; dismiss() }.buttonStyle(.borderedProminent).disabled(project.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
    }.padding(28).frame(width: 440).textFieldStyle(.roundedBorder) }
}
struct TaskEditor: View {
    @Bindable var store: AppStore
    @State var task: WorkTask
    @Environment(\.dismiss) private var dismiss
    var body: some View { VStack(alignment: .leading, spacing: 18) {
        Text("Edit task").font(.title2)
        TextField("Title", text: $task.title)
        Picker("Project", selection: $task.projectID) { Text("No project").tag(nil as UUID?); ForEach(store.archive.projects) { Text($0.name).tag(Optional($0.id)) } }
        HStack { Text("Estimated minutes"); TextField("Minutes", value: Binding(get: { Int(task.estimate / 60) }, set: { task.estimate = Double(max(0, min(525600, $0))) * 60 }), format: .number).frame(width: 90) }
        let actual = Analytics.taskSeconds(task.id, sessions: store.archive.sessions)
        Text("Recorded: \(Int(actual / 60)) min · Estimated remaining: \(Int(max(0, task.estimate - actual) / 60)) min").font(.caption).foregroundStyle(.secondary)
        Text("An estimate is a planning aid; it does not measure how much work remains.").font(.caption).foregroundStyle(.secondary)
        Toggle("Completed", isOn: $task.complete)
        HStack { Button("Cancel") { dismiss() }; Spacer(); Button("Save") { store.update { a in if let i = a.tasks.firstIndex(where: { $0.id == task.id }) { a.tasks[i] = task } }; dismiss() }.buttonStyle(.borderedProminent).disabled(task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
    }.padding(28).frame(width: 480).textFieldStyle(.roundedBorder) }
}

struct SessionContextEditor: View {
    @Bindable var store: AppStore
    @State private var intention = ""
    @State private var project: UUID?
    @State private var task: UUID?
    @Environment(\.dismiss) private var dismiss
    var body: some View { VStack(alignment: .leading, spacing: 18) {
        Text("Your focus intention").font(.title2)
        TextField("Intention", text: $intention)
        Picker("Project", selection: $project) { Text("No project").tag(nil as UUID?); ForEach(store.archive.projects) { Text($0.name).tag(Optional($0.id)) } }
        Picker("Task", selection: $task) { Text("No task").tag(nil as UUID?); ForEach(store.archive.tasks.filter { $0.projectID == project }) { Text($0.title).tag(Optional($0.id)) } }
        Text("Time already recorded keeps its original project and task. The new context applies from this moment onward.").font(.caption).foregroundStyle(.secondary)
        HStack { Button("Cancel") { dismiss() }; Spacer(); Button("Save context") { store.changeContext(SessionContext(intention: intention, projectID: project, taskID: task)) }.buttonStyle(.borderedProminent).disabled(!store.isActive) }
    }.padding(28).frame(width: 480).textFieldStyle(.roundedBorder)
        .onAppear { intention = store.current?.intention ?? ""; project = store.current?.projectID; task = store.current?.taskID }
        .onChange(of: project) { _, value in if !store.archive.tasks.contains(where: { $0.id == task && $0.projectID == value }) { task = nil } }
    }
}
struct InterruptionEditor: View {
    @Bindable var store: AppStore
    @State private var category = InterruptionCategory.other
    @State private var note = ""
    @State private var pause = true
    @Environment(\.dismiss) private var dismiss
    var body: some View { VStack(alignment: .leading, spacing: 18) {
        Text("Record an interruption").font(.title2)
        Picker("Category", selection: $category) { ForEach(InterruptionCategory.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
        TextField("Optional reason", text: $note, axis: .vertical)
        Toggle("Pause the session", isOn: $pause)
        Text("This is a self-reported observation. Applications and websites are not monitored for this record.").font(.caption).foregroundStyle(.secondary)
        HStack { Button("Cancel") { dismiss() }; Spacer(); Button("Record") { store.recordInterruption(category: category, note: note, pause: pause) }.buttonStyle(.borderedProminent).disabled(!store.isActive || note.count > 2000) }
    }.padding(28).frame(width: 460).textFieldStyle(.roundedBorder) }
}
