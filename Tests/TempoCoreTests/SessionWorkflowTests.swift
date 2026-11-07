// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import Testing
@testable import TempoCore
struct SessionWorkflowTests {
    let wall = Date(timeIntervalSince1970: 1700000000)
    @Test func switchContextPreservesSegmentAttribution() throws {
        let a = Project(name: "A"), b = Project(name: "B")
        let first = WorkTask(title: "First", projectID: a.id), second = WorkTask(title: "Second", projectID: b.id)
        var engine = TimerEngine()
        try engine.start(duration: 600, intention: "First", projectID: a.id, taskID: first.id, wall: wall, monotonic: 0)
        try engine.changeContext(SessionContext(intention: "Second", projectID: b.id, taskID: second.id), wall: wall.addingTimeInterval(60), monotonic: 60)
        try engine.finish(wall: wall.addingTimeInterval(150), monotonic: 150)
        let session = try #require(engine.session)
        #expect(session.focused == 150)
        #expect(Analytics.projectSeconds(a.id, sessions: [session]) == 60)
        #expect(Analytics.projectSeconds(b.id, sessions: [session]) == 90)
        #expect(Analytics.taskSeconds(first.id, sessions: [session]) == 60)
        #expect(Analytics.taskSeconds(second.id, sessions: [session]) == 90)
        #expect(session.contextRevisions?.first?.previous.intention == "First")
        var archive = Archive(); archive.projects = [a,b]; archive.tasks = [first,second]; archive.sessions = [session]
        #expect(try Portability.decode(Portability.json(archive)) == archive)
    }
    @Test func contextSwitchWhilePausedDoesNotAccrueFocus() throws {
        var engine = TimerEngine()
        try engine.start(duration: 600, intention: "First", wall: wall, monotonic: 0)
        try engine.pause(wall: wall.addingTimeInterval(10), monotonic: 10)
        try engine.changeContext(SessionContext(intention: "Second"), wall: wall.addingTimeInterval(50), monotonic: 50)
        #expect(engine.session?.status == .paused)
        try engine.resume(wall: wall.addingTimeInterval(100), monotonic: 100)
        try engine.finish(wall: wall.addingTimeInterval(120), monotonic: 120)
        #expect(engine.session?.focused == 30)
        #expect(engine.session?.paused == 90)
    }
    @Test func legacyContextsAreFrozenBeforeSwitch() throws {
        let a = UUID(), b = UUID()
        var original = TimerEngine(); try original.start(duration: 600, intention: "Legacy", projectID: a, wall: wall, monotonic: 0)
        var stored = try #require(original.session); stored.segments[0].context = nil
        var engine = TimerEngine(); engine.restore(stored, wall: wall, monotonic: 0)
        try engine.changeContext(SessionContext(intention: "New", projectID: b), wall: wall.addingTimeInterval(40), monotonic: 40)
        try engine.finish(wall: wall.addingTimeInterval(60), monotonic: 60)
        #expect(Analytics.projectSeconds(a, sessions: [try #require(engine.session)]) == 40)
        #expect(Analytics.projectSeconds(b, sessions: [try #require(engine.session)]) == 20)
    }
    @Test func interruptionCanPauseOrJustRecord() throws {
        var engine = TimerEngine(); try engine.start(duration: 600, intention: "Read", wall: wall, monotonic: 0)
        try engine.interrupt(category: .conversation, note: "Question", pauseSession: true, wall: wall.addingTimeInterval(20), monotonic: 20)
        #expect(engine.session?.status == .paused)
        #expect(engine.snapshot(monotonic: 200)?.focused == 20)
        try engine.resume(wall: wall.addingTimeInterval(200), monotonic: 200)
        try engine.interrupt(category: .notification, note: "Noticed only", pauseSession: false, wall: wall.addingTimeInterval(220), monotonic: 220)
        try engine.finish(wall: wall.addingTimeInterval(230), monotonic: 230)
        #expect(engine.session?.focused == 50); #expect(engine.session?.interruptions?.count == 2)
    }
    @Test func cycleOptInAndEndOfCycleRules() throws {
        var engine = TimerEngine(); try engine.start(duration: 60, intention: "", wall: wall, monotonic: 0)
        try engine.finish(wall: wall.addingTimeInterval(60), monotonic: 60)
        let focus = try #require(engine.session)
        var cycle = Cycle(); cycle.completed = 4
        #expect(CyclePolicy.continuation(after: focus, cycle: cycle, naturalDeadline: true) == .none)
        cycle.automaticBreaks = true
        #expect(CyclePolicy.continuation(after: focus, cycle: cycle, naturalDeadline: true) == .longBreak)
        #expect(CyclePolicy.continuation(after: focus, cycle: cycle, naturalDeadline: false) == .none)
        try engine.start(kind: .longBreak, duration: 60, intention: "Rest", wall: wall, monotonic: 0)
        try engine.finish(wall: wall.addingTimeInterval(60), monotonic: 60)
        let longBreak = try #require(engine.session)
        cycle.automaticFocus = true
        #expect(CyclePolicy.continuation(after: longBreak, cycle: cycle, naturalDeadline: true) == .none)
        cycle.continueAfterLongBreak = true
        #expect(CyclePolicy.continuation(after: longBreak, cycle: cycle, naturalDeadline: true) == .focus)
        cycle.enabled = false
        #expect(CyclePolicy.continuation(after: longBreak, cycle: cycle, naturalDeadline: true) == .none)
    }
    @Test func expiredTimerCannotSplitOffExtraTime() throws {
        var engine = TimerEngine(); try engine.start(duration: 60, intention: "Deadline", wall: wall, monotonic: 0)
        #expect(throws: TempoError.self) { try engine.changeContext(SessionContext(intention: "Too late"), wall: wall.addingTimeInterval(100), monotonic: 100) }
        #expect(engine.session?.status == .completed)
        #expect(engine.session?.active == 60)
        #expect(engine.session?.contextRevisions == nil)
    }
    @Test func terminalContextCannotBeEdited() throws {
        var engine = TimerEngine(); try engine.start(duration: 60, intention: "Done", wall: wall, monotonic: 0)
        try engine.finish(wall: wall.addingTimeInterval(60), monotonic: 60)
        #expect(throws: TempoError.self) { try engine.changeContext(SessionContext(intention: "Edit"), wall: wall, monotonic: 60) }
    }
}
