// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import Testing
@testable import TempoCore
struct TimerTests {
    let start = Date(timeIntervalSince1970: 1700000000)
    func running(_ duration: Double? = 1500, kind: SessionKind = .focus) throws -> TimerEngine {
        var timer = TimerEngine(); try timer.start(kind: kind, duration: duration, intention: "Read", wall: start, monotonic: 100); return timer
    }
    @Test func pauseDoesNotAccrueFocus() throws {
        var t = try running(); try t.pause(wall: start.addingTimeInterval(60), monotonic: 160)
        #expect(t.snapshot(monotonic: 3760)?.focused == 60)
        try t.resume(wall: start.addingTimeInterval(3660), monotonic: 3760)
        try t.finish(wall: start.addingTimeInterval(3720), monotonic: 3820)
        #expect(t.session?.focused == 120); #expect(t.session?.paused == 3600)
    }
    @Test func completionCapsAtDeadlineAfterSleep() throws {
        var t = try running(60); let completed = t.reconcile(wall: start.addingTimeInterval(900), monotonic: 1000); #expect(completed)
        #expect(t.session?.active == 60); #expect(t.session?.ended == start.addingTimeInterval(60))
        try t.finish(wall: start.addingTimeInterval(1000), monotonic: 1100)
        #expect(t.session?.active == 60)
    }
    @Test(arguments: [-86400.0, 86400.0]) func wallClockDoesNotControlLiveDuration(shift: Double) throws {
        var t = try running(); try t.finish(wall: start.addingTimeInterval(shift), monotonic: 160)
        #expect(t.session?.focused == 60)
    }
    @Test func extensionAndReduction() throws {
        var t = try running(60); try t.adjust(by: 60, wall: start, monotonic: 130)
        #expect(t.remaining(monotonic: 130) == 90)
        try t.adjust(by: -100, wall: start.addingTimeInterval(30), monotonic: 130)
        #expect(t.session?.status == .completed); #expect(t.session?.active == 30)
    }
    @Test func rejectsDoubleStartAndInvalidActions() throws {
        var t = try running(); #expect(throws: TempoError.self) { try t.start(duration: 60, intention: "", wall: start, monotonic: 100) }
        #expect(throws: TempoError.self) { try t.resume(wall: start, monotonic: 100) }
        try t.finish(abandon: true, wall: start.addingTimeInterval(5), monotonic: 105)
        #expect(t.session?.status == .abandoned)
    }
    @Test func restartRestoresRemainingAndLabelsEstimate() throws {
        var t = try running(300); t.checkpoint(monotonic: 160)
        var recovered = TimerEngine(); recovered.restore(try #require(t.session), wall: start.addingTimeInterval(180), monotonic: 5)
        #expect(recovered.remaining(monotonic: 5) == 120); #expect(recovered.session?.recoveryNote != nil)
    }
    @Test func clockBackwardAcrossRestartStopsRecovery() throws {
        let t = try running(); var recovered = TimerEngine()
        recovered.restore(try #require(t.session), wall: start.addingTimeInterval(-100), monotonic: 1)
        #expect(recovered.session?.status == .interrupted)
    }
    @Test func pausedRecoveryStaysPaused() throws {
        var t = try running(); try t.pause(wall: start.addingTimeInterval(60), monotonic: 160)
        var recovered = TimerEngine(); recovered.restore(try #require(t.session), wall: start.addingTimeInterval(7200), monotonic: 1)
        #expect(recovered.session?.focused == 60); #expect(recovered.session?.status == .paused)
    }
    @Test func breaksAndOpenEnded() throws {
        var t = try running(300, kind: .shortBreak); try t.finish(wall: start.addingTimeInterval(300), monotonic: 400)
        #expect(t.session?.focused == 0); #expect(t.session?.active == 300)
        t = try running(nil, kind: .stopwatch); #expect(t.remaining(monotonic: 1000) == nil); #expect(t.snapshot(monotonic: 1000)?.focused == 900)
    }
    @Test func cycleChoosesLongBreak() {
        var cycle = Cycle(); cycle.completed = 3; #expect(cycle.nextBreak == .shortBreak)
        cycle.completed = 4; #expect(cycle.nextBreak == .longBreak)
    }
    @Test func sqliteAndPortableRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let db = try TempoDatabase(url: dir.appendingPathComponent("data.sqlite"))
        var archive = Archive(); archive.sessions = [try #require(running().session)]
        archive.projects = [Project(name: "Study")]; archive.tasks = [WorkTask(title: "Notes", projectID: archive.projects[0].id)]
        try db.save(archive); #expect(try db.load() == archive)
        let decoded = try Portability.decode(Portability.json(archive)); #expect(decoded == archive)
        let merged = try Portability.merge(decoded, into: archive); #expect(merged.sessions.count == 1)
    }
    @Test func importedActiveTimerCannotTakeOver() throws {
        var incoming = Archive(); incoming.sessions = [try #require(running().session)]
        let merged = try Portability.merge(incoming, into: Archive())
        #expect(merged.sessions[0].status == .interrupted)
    }
    @Test func unsafeImportsRejected() throws {
        var archive = Archive(); archive.schemaVersion = 2
        #expect(throws: TempoError.self) { try archive.validated() }
        archive = Archive(); archive.sessions = [try #require(running().session)]; archive.sessions.append(archive.sessions[0])
        #expect(throws: TempoError.self) { try archive.validated() }
    }
    @Test func midnightAndDSTSplitMeasuredTime() throws {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = try #require(TimeZone(identifier: "Europe/Rome"))
        let date = try #require(ISO8601DateFormatter().date(from: "2026-10-24T21:30:00Z"))
        var t = TimerEngine(); try t.start(duration: 7200, intention: "Night", wall: date, monotonic: 0)
        try t.finish(wall: date.addingTimeInterval(7200), monotonic: 7200)
        let s = try #require(t.session), days = Analytics.days([s], ending: date.addingTimeInterval(7200), count: 2, calendar: cal)
        #expect(days.map(\.seconds).reduce(0,+) == 7200); #expect(days[0].seconds == 1800)
    }
    @Test func actualDSTFallbackDoesNotChangeDuration() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-10-25T00:30:00Z"))
        var t = TimerEngine(); try t.start(duration: 7200, intention: "DST", wall: date, monotonic: 0)
        try t.finish(wall: date.addingTimeInterval(7200), monotonic: 7200)
        #expect(t.session?.focused == 7200)
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = try #require(TimeZone(identifier: "Europe/Rome"))
        #expect(Analytics.days([try #require(t.session)], ending: date.addingTimeInterval(7200), count: 1, calendar: calendar)[0].seconds == 7200)
    }
    @Test func reductionsAfterMultipleSegmentsKeepMeasuredWork() throws {
        var t = try running(600)
        try t.pause(wall: start.addingTimeInterval(100), monotonic: 200)
        try t.resume(wall: start.addingTimeInterval(200), monotonic: 300)
        try t.adjust(by: -590, wall: start.addingTimeInterval(210), monotonic: 310)
        #expect(t.session?.active == 110); #expect(t.session?.paused == 100)
        #expect(t.session?.status == .completed)
    }
    @Test func csvNeutralizesSpreadsheetFormula() throws {
        var t = TimerEngine(); try t.start(duration: 60, intention: "=CMD()", wall: start, monotonic: 0)
        #expect(Portability.csv([try #require(t.session)]).contains("'=CMD()"))
    }
}
