// SPDX-License-Identifier: AGPL-3.0-only
import Foundation

public enum SessionKind: String, Codable, CaseIterable, Sendable { case focus, shortBreak, longBreak, stopwatch, custom, openEnded
    public var isFocus: Bool { self != .shortBreak && self != .longBreak }
    public var label: String { switch self { case .focus: "Focus"; case .shortBreak: "Short break"; case .longBreak: "Long break"; case .stopwatch: "Stopwatch"; case .custom: "Custom"; case .openEnded: "Open-ended focus" } }
}
public enum SessionStatus: String, Codable, Sendable { case running, paused, completed, abandoned, interrupted }
public struct Segment: Codable, Equatable, Sendable {
    public var start: Date
    public var end: Date?
    public var elapsed: Double
    public var isPause: Bool
    public var context: SessionContext?
}
public struct FocusSession: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var intention: String
    public var projectID: UUID?
    public var taskID: UUID?
    public var kind: SessionKind
    public var planned: Double?
    public var started: Date
    public var ended: Date?
    public var status: SessionStatus = .running
    public var segments: [Segment]
    public var revision = 1
    public var recoveryNote: String?
    public var reflection = ""
    public var rating: Int?
    public var deletedAt: Date?
    public var contextRevisions: [ContextRevision]?
    public var interruptions: [SessionInterruption]?
    public var focused: Double { kind.isFocus ? segments.filter { !$0.isPause }.reduce(0) { $0 + $1.elapsed } : 0 }
    public var active: Double { segments.filter { !$0.isPause }.reduce(0) { $0 + $1.elapsed } }
    public var paused: Double { segments.filter(\.isPause).reduce(0) { $0 + $1.elapsed } }
    public var isActive: Bool { status == .running || status == .paused }
}
public struct Project: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name: String
    public var notes = ""
    public var status = "Active"
    public var created = Date()
    public init(name: String) { self.name = name }
}
public struct WorkTask: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var title: String
    public var projectID: UUID?
    public var complete = false
    public var estimate: Double = 0
    public var created = Date()
    public init(title: String, projectID: UUID? = nil) { self.title = title; self.projectID = projectID }
}
public struct Idea: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var title: String
    public var detail = ""
    public var category = "Feature"
    public var priority = "Normal"
    public var status = "Pending"
    public var created = Date()
    public var modified = Date()
    public var implementation = ""
    public init(title: String) { self.title = title }
}
public struct Cycle: Codable, Equatable, Sendable {
    public var enabled = true
    public var focus: Double = 1500
    public var shortBreak: Double = 300
    public var longBreak: Double = 900
    public var count = 4
    public var completed = 0
    public var automaticBreaks: Bool?
    public var automaticFocus: Bool?
    public var continueAfterLongBreak: Bool?
    public init() {}
    public var nextBreak: SessionKind { completed > 0 && completed % max(1, count) == 0 ? .longBreak : .shortBreak }
}
public struct Settings: Codable, Equatable, Sendable {
    public var cycle = Cycle()
    public var presets: [Int] = [15,25,45,50,60,90]
    public var digitalTimer = false
    public var dailyGoal = 90
    public var notifications = false
    public var reflectionPrompts = true
    public var hidePrivateTitles = true
    public var distractionEnabled = false
    public var distractingApps: [String] = []
    // Optional additions preserve decoding of version-1 archives made before browser support.
    public var websiteDomains: [String]?
    public var websiteBlockingEnabled: Bool?
    public var distractionProfiles: [DistractionProfile]?
    public init() {}
}
public enum DataProvenance: String, Codable, Sendable { case recorded, simulated }
public struct Archive: Codable, Equatable, Sendable {
    public var schemaVersion = 1
    public var application = "org.openrecode.tempo"
    public var provenance: DataProvenance?
    public var exported = Date()
    public var sessions: [FocusSession] = []
    public var projects: [Project] = []
    public var tasks: [WorkTask] = []
    public var ideas: [Idea] = []
    public var settings = Settings()
    public init() {}
    public func validated() throws -> Archive {
        guard schemaVersion == 1, application == "org.openrecode.tempo", sessions.count <= 100_000, projects.count <= 10_000, tasks.count <= 100_000, ideas.count <= 10_000 else { throw TempoError.invalidImport }
        guard Set(sessions.map(\.id)).count == sessions.count, Set(projects.map(\.id)).count == projects.count, Set(tasks.map(\.id)).count == tasks.count, Set(ideas.map(\.id)).count == ideas.count, sessions.filter(\.isActive).count <= 1 else { throw TempoError.invalidImport }
        let projectIDs = Set(projects.map(\.id)), taskIDs = Set(tasks.map(\.id))
        for s in sessions {
            guard s.revision > 0, s.intention.count <= 10000, s.planned.map({ $0.isFinite && $0 >= 1 && $0 <= 86400 }) ?? true, !s.segments.isEmpty,
                  s.projectID.map(projectIDs.contains) ?? true, s.taskID.map(taskIDs.contains) ?? true,
                  s.segments.allSatisfy({ $0.elapsed.isFinite && $0.elapsed >= 0 && $0.elapsed <= 31536000 }),
                  s.segments.allSatisfy({ segment in segment.end.map { $0 >= segment.start } ?? true }),
                  (s.interruptions ?? []).count <= 10000,
                  (s.interruptions ?? []).allSatisfy({ $0.note.count <= 2000 && $0.at.timeIntervalSince1970.isFinite }),
                  (s.contextRevisions ?? []).count <= 10000,
                  s.segments.allSatisfy({ segment in
                      guard let context = segment.context else { return true }
                      return context.intention.count <= 10000 && (context.projectID.map(projectIDs.contains) ?? true) && (context.taskID.map(taskIDs.contains) ?? true)
                  }),
                  s.rating.map({ (1...5).contains($0) }) ?? true else { throw TempoError.invalidImport }
        }
        guard tasks.allSatisfy({ ($0.projectID.map(projectIDs.contains) ?? true) && $0.estimate.isFinite && $0.estimate >= 0 }), (1...24).contains(settings.cycle.count), (1...1440).contains(settings.dailyGoal), settings.presets.allSatisfy({ (1...1440).contains($0) }), [settings.cycle.focus, settings.cycle.shortBreak, settings.cycle.longBreak].allSatisfy({ $0.isFinite && (1...86400).contains($0) }) else { throw TempoError.invalidImport }
        guard (settings.websiteDomains ?? []).count <= 500,
              (settings.websiteDomains ?? []).allSatisfy({ DomainPolicy.normalize($0) == $0 }),
              (settings.distractionProfiles ?? []).count <= 100,
              (settings.distractionProfiles ?? []).allSatisfy({ profile in
                  !profile.name.isEmpty && profile.name.count <= 200 && profile.domains.count <= 500 && profile.domains.allSatisfy({ DomainPolicy.normalize($0) == $0 }) && profile.applicationIDs.count <= 500
              }) else { throw TempoError.invalidImport }
        return self
    }
}
public enum TempoError: Error, LocalizedError { case invalidTransition, invalidDuration, invalidImport, database(String)
    public var errorDescription: String? { switch self { case .invalidTransition: "This timer action is unavailable in the current state."; case .invalidDuration: "Choose a duration between one second and 24 hours."; case .invalidImport: "The file contains unsupported, duplicate, or invalid Tempo data."; case .database(let message): "Storage error: \(message)" } }
}
