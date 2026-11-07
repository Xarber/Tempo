// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
public struct DailyTotal: Identifiable, Sendable { public var date: Date; public var seconds: Double; public var id: Date { date } }
public enum Analytics {
    public static func focus(_ sessions: [FocusSession], from: Date, to: Date) -> Double {
        sessions.filter { $0.deletedAt == nil && $0.kind.isFocus }.reduce(0) { total, s in
            total + s.segments.filter { !$0.isPause }.reduce(0) { sum, segment in
                // Segment elapsed is authoritative. Wall timestamps only place its measured duration on the calendar.
                let end = segment.start.addingTimeInterval(segment.elapsed)
                return sum + max(0, min(end, to).timeIntervalSince(max(segment.start, from)))
            }
        }
    }
    public static func days(_ sessions: [FocusSession], ending: Date, count: Int, calendar: Calendar = .current) -> [DailyTotal] {
        let today = calendar.startOfDay(for: ending)
        return (0..<max(0,count)).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today), let end = calendar.date(byAdding: .day, value: 1, to: date) else { return nil }
            return DailyTotal(date: date, seconds: focus(sessions, from: date, to: end))
        }
    }
    public static func taskSeconds(_ id: UUID, sessions: [FocusSession]) -> Double { attributedSeconds(id, sessions: sessions, project: false) }
    public static func projectSeconds(_ id: UUID, sessions: [FocusSession]) -> Double { attributedSeconds(id, sessions: sessions, project: true) }
    private static func attributedSeconds(_ id: UUID, sessions: [FocusSession], project: Bool) -> Double {
        sessions.filter { $0.deletedAt == nil && $0.kind.isFocus }.reduce(0) { total, session in
            total + session.segments.filter { !$0.isPause }.reduce(0) { sum, segment in
                let context = segment.context ?? SessionContext(intention: session.intention, projectID: session.projectID, taskID: session.taskID)
                return sum + ((project ? context.projectID : context.taskID) == id ? segment.elapsed : 0)
            }
        }
    }
}
