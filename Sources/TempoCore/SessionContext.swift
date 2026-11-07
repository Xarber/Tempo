// SPDX-License-Identifier: AGPL-3.0-only
import Foundation

public struct SessionContext: Codable, Equatable, Sendable {
    public var intention: String
    public var projectID: UUID?
    public var taskID: UUID?
    public init(intention: String, projectID: UUID? = nil, taskID: UUID? = nil) {
        self.intention = intention; self.projectID = projectID; self.taskID = taskID
    }
}
public struct ContextRevision: Codable, Equatable, Sendable {
    public var at: Date
    public var previous: SessionContext
    public var current: SessionContext
}
public enum InterruptionCategory: String, Codable, CaseIterable, Sendable {
    case notification = "Notification", website = "Website", conversation = "Conversation", phone = "Phone call", otherTask = "Other task", personalBreak = "Personal break", other = "Other"
}
public struct SessionInterruption: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var at: Date
    public var category: InterruptionCategory
    public var note: String
    public var pausedSession: Bool
}
public enum CycleContinuation: Equatable, Sendable { case none, focus, shortBreak, longBreak }
public enum CyclePolicy {
    /// Only natural deadlines may progress automatically; explicit early finishes never do.
    public static func continuation(after session: FocusSession, cycle: Cycle, naturalDeadline: Bool) -> CycleContinuation {
        guard cycle.enabled, naturalDeadline, session.status == .completed else { return .none }
        if session.kind.isFocus {
            guard cycle.automaticBreaks == true else { return .none }
            return cycle.nextBreak == .longBreak ? .longBreak : .shortBreak
        }
        guard cycle.automaticFocus == true, session.kind != .longBreak || cycle.continueAfterLongBreak == true else { return .none }
        return .focus
    }
}
