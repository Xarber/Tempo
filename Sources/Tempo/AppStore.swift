// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import TempoCore
import UserNotifications
import AppKit
import ServiceManagement

@MainActor @Observable final class AppStore {
    var archive = Archive()
    var engine = TimerEngine()
    var intention = ""
    var projectID: UUID?
    var taskID: UUID?
    var minutes = 25
    var kind = SessionKind.focus
    var error: String?
    var recovery = ""
    var now = Date()
    var reflectionID: UUID?
    var editingContext = false
    var recordingInterruption = false
    var developerUntil: Date?
    var versionTaps = 0
    var importPreview: Archive?
    var importSummary = ""
    var blockingReminder: String?
    var browserBridgeError: String?
    private var bridgeURL: URL?
    private var database: TempoDatabase?
    private let clock = ContinuousClock()
    private let origin = ContinuousClock.now
    private var ticker: Task<Void, Never>?
    private var completion: Task<Void, Never>?
    private var notificationSession: UUID?
    private var activityObserver: NSObjectProtocol?
    private var lastCheckpoint = Date()
    var sample: Double { let d = origin.duration(to: clock.now).components; return Double(d.seconds) + Double(d.attoseconds) / 1e18 }
    var current: FocusSession? { _ = now; return engine.snapshot(monotonic: sample) }
    var isActive: Bool { current?.isActive == true }
    var developerVisible: Bool { developerUntil.map { $0 > now } ?? false }
    var remaining: Double { _ = now; guard isActive else { return Double(minutes * 60) }; return engine.remaining(monotonic: sample) ?? current?.active ?? 0 }
    var timeText: String { Self.format(remaining) }
    static func format(_ seconds: Double) -> String { let value = max(0, Int(ceil(seconds))); return value >= 3600 ? String(format: "%d:%02d:%02d", value / 3600, (value / 60) % 60, value % 60) : String(format: "%02d:%02d", value / 60, value % 60) }
    var isQA: Bool { (Bundle.main.object(forInfoDictionaryKey: "TempoDataNamespace") as? String ?? "Tempo") != "Tempo" }
    var history: [FocusSession] { archive.sessions.filter { $0.deletedAt == nil && !$0.isActive }.sorted { $0.started > $1.started } }
    var today: Double { let start = Calendar.current.startOfDay(for: now); return Analytics.focus(archive.sessions, from: start, to: now) }
    init() {
        do {
            let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let namespace = Bundle.main.object(forInfoDictionaryKey: "TempoDataNamespace") as? String ?? "Tempo"
            let folder = support.appendingPathComponent("OpenRecode/" + namespace, isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: folder.path)
            bridgeURL = folder.appendingPathComponent("browser-state.json")
            let db = try TempoDatabase(url: folder.appendingPathComponent("tempo.sqlite")); database = db
            archive = try db.load()
            archive.provenance = isQA ? .simulated : (archive.provenance ?? .recorded)
            if let active = archive.sessions.first(where: \.isActive) {
                engine.restore(active, wall: Date(), monotonic: sample); recovery = engine.session?.recoveryNote ?? ""
                capture(); try db.save(archive)
            }
        } catch { self.error = error.localizedDescription }
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }; self.tick()
            }
        }
        activityObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] notification in
            let identifier = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier
            Task { @MainActor [weak self] in
                guard let self, self.archive.settings.distractionEnabled, self.current?.status == .running, self.current?.kind.isFocus == true, let identifier, self.archive.settings.distractingApps.contains(identifier) else { return }
                self.blockingReminder = "A configured distracting app is active. Return to your intention when you’re ready."
            }
        }
        writeBrowserPolicy()
        scheduleCompletion()
    }
    @discardableResult func perform(_ operation: () throws -> Void) -> Bool {
        guard database != nil else { error = "Storage is unavailable. Resolve the storage error before starting a session."; return false }
        let oldArchive = archive, oldEngine = engine
        do { try operation(); capture(); try database?.save(archive); writeBrowserPolicy(); scheduleCompletion(); return true }
        catch { archive = oldArchive; engine = oldEngine; self.error = error.localizedDescription; return false }
    }
    func update(_ operation: (inout Archive) -> Void) { perform { operation(&archive) } }
    func start() {
        recovery = ""
        perform {
            let duration: Double? = kind == .stopwatch || kind == .openEnded ? nil : Double(minutes * 60)
            try engine.start(kind: kind, duration: duration, intention: intention.trimmingCharacters(in: .whitespacesAndNewlines), projectID: projectID, taskID: taskID, wall: Date(), monotonic: sample)
        }
    }
    func startBreak() {
        let next = archive.settings.cycle.nextBreak; kind = next
        minutes = max(1, Int((next == .longBreak ? archive.settings.cycle.longBreak : archive.settings.cycle.shortBreak) / 60))
        intention = "Time to recharge"; projectID = nil; taskID = nil; start()
    }
    func pauseResume() { perform { if current?.status == .paused { try engine.resume(wall: Date(), monotonic: sample) } else { try engine.pause(wall: Date(), monotonic: sample) } } }
    func finish(abandon: Bool = false) {
        let wasActive = isActive
        if perform({ try engine.finish(abandon: abandon, wall: Date(), monotonic: sample) }), wasActive, let finished = current { handleCompletion(finished, naturalDeadline: false) }
    }
    func adjust(_ seconds: Double) {
        if perform({ try engine.adjust(by: seconds, wall: Date(), monotonic: sample) }), let finished = current, !finished.isActive { handleCompletion(finished, naturalDeadline: false) }
    }
    func changeContext(_ context: SessionContext) {
        if perform({ try engine.changeContext(context, wall: Date(), monotonic: sample) }) {
            intention = context.intention; projectID = context.projectID; taskID = context.taskID; editingContext = false
        }
    }
    func recordInterruption(category: InterruptionCategory, note: String, pause: Bool) {
        if perform({ try engine.interrupt(category: category, note: note, pauseSession: pause, wall: Date(), monotonic: sample) }) { recordingInterruption = false }
    }
    func restart() { guard let s = current else { return }; if s.isActive { finish(abandon: true) }; kind = s.kind; minutes = Int((s.planned ?? 1500) / 60); intention = s.intention; projectID = s.projectID; taskID = s.taskID; start() }
    func focusTask(_ task: WorkTask) { guard !isActive else { error = "Finish or abandon the current session first."; return }; taskID = task.id; projectID = task.projectID; intention = task.title; kind = .focus; minutes = Int(archive.settings.cycle.focus / 60); recovery = ""; start() }
    func tick() {
        now = Date()
        if developerUntil.map({ $0 < now }) == true { developerUntil = nil; versionTaps = 0 }
        if current?.status == .running, current?.planned != nil, remaining <= 0 {
            if perform({ _ = engine.reconcile(wall: now, monotonic: sample) }), let finished = current { handleCompletion(finished, naturalDeadline: true) }
        }
        if isActive && now.timeIntervalSince(lastCheckpoint) >= 15 { perform { engine.checkpoint(monotonic: sample) }; lastCheckpoint = now }
    }
    func capture() {
        guard let s = current else { return }
        if let index = archive.sessions.firstIndex(where: { $0.id == s.id }) {
            let previous = archive.sessions[index]
            var merged = s; merged.reflection = previous.reflection; merged.rating = previous.rating; merged.deletedAt = previous.deletedAt
            archive.sessions[index] = merged
            if previous.status != .completed && s.status == .completed && s.kind.isFocus { archive.settings.cycle.completed += 1 }
        } else { archive.sessions.append(s) }
    }
    func handleCompletion(_ finished: FocusSession, naturalDeadline: Bool) {
        guard finished.status == .completed else { return }
        if !finished.kind.isFocus { kind = .focus; minutes = max(1, Int(archive.settings.cycle.focus / 60)); intention = "" }
        else if archive.settings.reflectionPrompts { reflectionID = finished.id }
        switch CyclePolicy.continuation(after: finished, cycle: archive.settings.cycle, naturalDeadline: naturalDeadline) {
        case .none: break
        case .shortBreak, .longBreak: startBreak()
        case .focus:
            if let previous = archive.sessions.reversed().first(where: { $0.kind.isFocus && $0.status == .completed && $0.deletedAt == nil }) {
                intention = previous.intention; projectID = previous.projectID; taskID = previous.taskID
            }
            kind = .focus; minutes = max(1, Int(archive.settings.cycle.focus / 60)); start()
        }
    }
    func scheduleCompletion() {
        completion?.cancel()
        if let previous = notificationSession, archive.sessions.first(where: { $0.id == previous })?.status != .completed {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["tempo-completion-" + previous.uuidString])
        }
        notificationSession = current?.id
        guard let session = current, session.status == .running, let remaining = engine.remaining(monotonic: sample), remaining > 0 else { return }
        completion = Task { [weak self] in
            try? await Task.sleep(for: .seconds(remaining))
            guard !Task.isCancelled else { return }; self?.tick()
        }
        if archive.settings.notifications {
            let content = UNMutableNotificationContent(); content.title = "Time for a pause"; content.body = "Your Tempo session is complete."; content.sound = .default
            let request = UNNotificationRequest(identifier: "tempo-completion-" + session.id.uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, remaining), repeats: false))
            Task { do { try await UNUserNotificationCenter.current().add(request) } catch { self.error = "Notification scheduling failed: \(error.localizedDescription)" } }
        }
    }
    func enableNotifications() {
        Task { do { let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound]); update { $0.settings.notifications = granted }; if !granted { error = "Notifications are not authorized. You can enable them in System Settings." } } catch { self.error = error.localizedDescription } }
    }
    func versionTap() { versionTaps += 1; if versionTaps >= 3 { developerUntil = Date().addingTimeInterval(30); versionTaps = 0 } }
    func touchDeveloper() { if developerVisible { developerUntil = Date().addingTimeInterval(30) } }
    func exportData(_ format: String) {
        perform { engine.checkpoint(monotonic: sample) }
        let panel = NSSavePanel(); panel.nameFieldStringValue = "Tempo-\(Date().formatted(.iso8601.year().month().day().dateSeparator(.dash))).\(format)"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { var export = archive; export.exported = Date(); let data = try format == "json" ? Portability.json(export) : Data((format == "csv" ? Portability.csv(export.sessions) : Portability.markdown(export)).utf8); try data.write(to: url, options: .atomic) } catch { self.error = error.localizedDescription }
    }
    func previewImport() {
        let panel = NSOpenPanel(); panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0; guard size <= 25_000_000 else { throw TempoError.invalidImport }
            let incoming = try Portability.decode(Data(contentsOf: url)); importPreview = incoming
            importSummary = "\(incoming.sessions.count) sessions, \(incoming.projects.count) projects, \(incoming.tasks.count) tasks, \(incoming.ideas.count) ideas. Existing IDs and settings stay unchanged. Incoming active timers become interrupted history."
        } catch { self.error = error.localizedDescription }
    }
    func applyImport() { guard let incoming = importPreview else { return }; perform { archive = try Portability.merge(incoming, into: archive) }; importPreview = nil }
    func saveReflection(id: UUID, note: String, rating: Int?) { update { archive in if let i = archive.sessions.firstIndex(where: { $0.id == id }) { archive.sessions[i].reflection = note; archive.sessions[i].rating = rating; archive.sessions[i].revision += 1 } }; reflectionID = nil }
    func writeBrowserPolicy(disabled: Bool = false) {
        guard let url = bridgeURL else { return }
        do {
            let policy = BrowserPolicy(session: disabled ? nil : current, settings: archive.settings, remaining: engine.remaining(monotonic: sample), wall: Date())
            let data = try JSONEncoder().encode(policy)
            try data.write(to: url, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            browserBridgeError = nil
        } catch { browserBridgeError = "Browser policy could not be saved. Browser restrictions will expire safely." }
    }
    func flush() { perform { engine.checkpoint(monotonic: sample) }; writeBrowserPolicy(disabled: true) }
}
