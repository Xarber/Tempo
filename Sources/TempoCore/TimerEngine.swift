// SPDX-License-Identifier: AGPL-3.0-only
import Foundation

/// The rendering clock never owns time. The injected continuous sample includes sleep.
public struct TimerEngine: Sendable {
    public private(set) var session: FocusSession?
    private var anchor: Double = 0
    private var base: Double = 0
    public init() {}
    public mutating func start(kind: SessionKind = .focus, duration: Double?, intention: String, projectID: UUID? = nil, taskID: UUID? = nil, wall: Date, monotonic: Double) throws {
        guard session?.isActive != true else { throw TempoError.invalidTransition }
        if let duration { guard duration.isFinite && (1...86400).contains(duration) else { throw TempoError.invalidDuration } }
        guard duration != nil || kind == .stopwatch || kind == .openEnded else { throw TempoError.invalidDuration }
        session = FocusSession(intention: intention, projectID: projectID, taskID: taskID, kind: kind, planned: duration, started: wall, segments: [Segment(start: wall, elapsed: 0, isPause: false, context: SessionContext(intention: intention, projectID: projectID, taskID: taskID))])
        anchor = monotonic; base = 0
    }
    public func snapshot(monotonic: Double) -> FocusSession? {
        guard var s = session, s.isActive, let index = s.segments.indices.last else { return session }
        s.segments[index].elapsed = base + max(0, monotonic - anchor)
        return s
    }
    public func remaining(monotonic: Double) -> Double? { guard let s = snapshot(monotonic: monotonic), let planned = s.planned else { return nil }; return max(0, planned - s.active) }
    @discardableResult public mutating func reconcile(wall: Date, monotonic: Double) -> Bool {
        guard let s = snapshot(monotonic: monotonic), s.status == .running, let planned = s.planned, s.active >= planned else { return false }
        let excess = s.active - planned
        session = s
        if let i = session?.segments.indices.last { session?.segments[i].elapsed = max(0, s.segments[i].elapsed - excess) }
        close(status: .completed, wall: wall.addingTimeInterval(-excess))
        return true
    }
    public mutating func pause(wall: Date, monotonic: Double) throws {
        _ = reconcile(wall: wall, monotonic: monotonic)
        guard session?.status == .running else { throw TempoError.invalidTransition }
        checkpoint(monotonic: monotonic); transition(paused: true, wall: wall, monotonic: monotonic)
    }
    public mutating func resume(wall: Date, monotonic: Double) throws {
        guard session?.status == .paused else { throw TempoError.invalidTransition }
        checkpoint(monotonic: monotonic); transition(paused: false, wall: wall, monotonic: monotonic)
    }
    public mutating func finish(abandon: Bool = false, wall: Date, monotonic: Double) throws {
        if reconcile(wall: wall, monotonic: monotonic) { return }
        guard session?.isActive == true else { if session?.status == .completed || session?.status == .abandoned { return }; throw TempoError.invalidTransition }
        checkpoint(monotonic: monotonic); close(status: abandon ? .abandoned : .completed, wall: wall)
    }
    public mutating func adjust(by seconds: Double, wall: Date, monotonic: Double) throws {
        guard let s = session, s.isActive, let planned = s.planned, seconds.isFinite, (1...86400).contains(planned + seconds) else { throw TempoError.invalidDuration }
        // Reducing a deadline must never erase focus already measured.
        let measured = snapshot(monotonic: monotonic)?.active ?? 0
        session?.planned = max(planned + seconds, measured); session?.revision += 1
        _ = reconcile(wall: wall, monotonic: monotonic)
    }
    public mutating func changeContext(_ context: SessionContext, wall: Date, monotonic: Double) throws {
        _ = reconcile(wall: wall, monotonic: monotonic)
        guard let current = session, current.isActive else { throw TempoError.invalidTransition }
        guard context.intention.count <= 10000 else { throw TempoError.invalidImport }
        let previous = SessionContext(intention: current.intention, projectID: current.projectID, taskID: current.taskID)
        guard previous != context else { return }
        checkpoint(monotonic: monotonic)
        // Freeze legacy segments before changing session-level fallback metadata.
        for i in session!.segments.indices where session!.segments[i].context == nil { session!.segments[i].context = previous }
        session?.intention = context.intention; session?.projectID = context.projectID; session?.taskID = context.taskID
        var revisions = session?.contextRevisions ?? []
        revisions.append(ContextRevision(at: wall, previous: previous, current: context)); session?.contextRevisions = revisions
        transition(paused: current.status == .paused, wall: wall, monotonic: monotonic)
    }
    public mutating func interrupt(category: InterruptionCategory, note: String, pauseSession: Bool, wall: Date, monotonic: Double) throws {
        _ = reconcile(wall: wall, monotonic: monotonic)
        guard session?.isActive == true, note.count <= 2000 else { throw TempoError.invalidTransition }
        if pauseSession && session?.status == .running { try pause(wall: wall, monotonic: monotonic) }
        var records = session?.interruptions ?? []
        records.append(SessionInterruption(at: wall, category: category, note: note, pausedSession: pauseSession))
        session?.interruptions = records; session?.revision += 1
    }
    public mutating func checkpoint(monotonic: Double) {
        session = snapshot(monotonic: monotonic)
        anchor = monotonic; base = session?.segments.last?.elapsed ?? 0
    }
    public mutating func restore(_ stored: FocusSession, wall: Date, monotonic: Double) {
        session = stored; anchor = monotonic; base = stored.segments.last?.elapsed ?? 0
        guard stored.isActive, let last = stored.segments.last else { return }
        // Across processes no monotonic instant survives. Wall-time recovery is explicitly labelled.
        let delta = wall.timeIntervalSince(last.start) - last.elapsed
        if delta < -2 || delta > 86400 * 7 {
            session?.status = .interrupted; session?.ended = wall
            session?.segments[stored.segments.count - 1].end = max(wall, last.start)
            session?.recoveryNote = "Clock discontinuity: timing stopped at the last saved checkpoint. Review this session."
        } else {
            base += max(0, delta); session?.segments[stored.segments.count - 1].elapsed = base
            session?.recoveryNote = "Recovered using wall-clock time since the saved segment. Duration across restart is estimated."
            _ = reconcile(wall: wall, monotonic: monotonic)
        }
        session?.revision += 1
    }
    private mutating func transition(paused: Bool, wall: Date, monotonic: Double) {
        guard let i = session?.segments.indices.last else { return }
        let segmentStart = session!.segments[i].start
        session?.segments[i].end = max(wall, segmentStart)
        let context = SessionContext(intention: session!.intention, projectID: session!.projectID, taskID: session!.taskID)
        session?.segments.append(Segment(start: wall, elapsed: 0, isPause: paused, context: context))
        session?.status = paused ? .paused : .running; session?.revision += 1
        anchor = monotonic; base = 0
    }
    private mutating func close(status: SessionStatus, wall: Date) {
        guard let i = session?.segments.indices.last else { return }
        let segmentStart = session!.segments[i].start
        session?.segments[i].end = max(wall, segmentStart)
        let sessionStart = session!.started
        session?.ended = max(wall, sessionStart); session?.status = status; session?.revision += 1
    }
}
