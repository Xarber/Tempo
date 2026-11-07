// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import CSQLite

/// Single-owner transactional snapshot repository. No partially saved timer/project graph.
public final class TempoDatabase {
    private var connection: OpaquePointer?
    public init(url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard sqlite3_open_v2(url.path, &connection, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else { throw TempoError.database("Cannot open database") }
        var versionStatement: OpaquePointer?
        guard sqlite3_prepare_v2(connection, "PRAGMA user_version", -1, &versionStatement, nil) == SQLITE_OK else { throw error() }
        let versionResult = sqlite3_step(versionStatement)
        let version = sqlite3_column_int(versionStatement, 0)
        sqlite3_finalize(versionStatement)
        guard versionResult == SQLITE_ROW, version <= 1 else { throw TempoError.database("Database schema is newer than this app. Original data was preserved.") }
        try execute("PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL; PRAGMA busy_timeout=3000; CREATE TABLE IF NOT EXISTS snapshots (id INTEGER PRIMARY KEY CHECK(id=1), schema_version INTEGER NOT NULL, payload BLOB NOT NULL); PRAGMA user_version=1;")
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
    deinit { sqlite3_close(connection) }
    public func load() throws -> Archive {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection, "SELECT payload FROM snapshots WHERE id=1", -1, &statement, nil) == SQLITE_OK else { throw error() }
        defer { sqlite3_finalize(statement) }
        let result = sqlite3_step(statement)
        if result == SQLITE_DONE { return Archive() }
        guard result == SQLITE_ROW, let bytes = sqlite3_column_blob(statement, 0) else { throw error() }
        let data = Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, 0)))
        return try JSONDecoder().decode(Archive.self, from: data).validated()
    }
    public func save(_ archive: Archive) throws {
        _ = try archive.validated()
        let data = try JSONEncoder().encode(archive)
        try execute("BEGIN IMMEDIATE")
        do {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(connection, "INSERT INTO snapshots(id,schema_version,payload) VALUES(1,1,?) ON CONFLICT(id) DO UPDATE SET payload=excluded.payload", -1, &statement, nil) == SQLITE_OK else { throw error() }
            defer { sqlite3_finalize(statement) }
            let result = data.withUnsafeBytes { bytes in
                sqlite3_bind_blob(statement, 1, bytes.baseAddress, Int32(bytes.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            }
            guard result == SQLITE_OK, sqlite3_step(statement) == SQLITE_DONE else { throw error() }
            try execute("COMMIT")
        } catch { try? execute("ROLLBACK"); throw error }
    }
    private func execute(_ sql: String) throws { guard sqlite3_exec(connection, sql, nil, nil, nil) == SQLITE_OK else { throw error() } }
    private func error() -> TempoError { .database(connection.map { String(cString: sqlite3_errmsg($0)) } ?? "Unavailable connection") }
}

public enum Portability {
    public static func json(_ archive: Archive) throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; return try encoder.encode(archive)
    }
    public static func decode(_ data: Data) throws -> Archive {
        guard data.count <= 25_000_000 else { throw TempoError.invalidImport }
        return try JSONDecoder().decode(Archive.self, from: data).validated()
    }
    /// Existing IDs win. Imported active timers become interrupted history, never a second running timer.
    public static func merge(_ incoming: Archive, into existing: Archive) throws -> Archive {
        _ = try incoming.validated()
        guard incoming.provenance != .simulated || existing.provenance == .simulated else { throw TempoError.invalidImport }
        var result = existing
        let projectIDs = Set(existing.projects.map(\.id)), taskIDs = Set(existing.tasks.map(\.id)), sessionIDs = Set(existing.sessions.map(\.id)), ideaIDs = Set(existing.ideas.map(\.id))
        result.projects += incoming.projects.filter { !projectIDs.contains($0.id) }
        result.tasks += incoming.tasks.filter { !taskIDs.contains($0.id) }
        result.ideas += incoming.ideas.filter { !ideaIDs.contains($0.id) }
        result.sessions += incoming.sessions.filter { !sessionIDs.contains($0.id) }.map { original in
            var s = original
            if s.isActive { s.status = .interrupted; s.ended = s.segments.last?.end ?? s.started; s.recoveryNote = "Imported active timer preserved as interrupted history."; if let i = s.segments.indices.last { s.segments[i].end = s.segments[i].end ?? s.segments[i].start.addingTimeInterval(s.segments[i].elapsed) } }
            return s
        }
        return try result.validated()
    }
    public static func csv(_ sessions: [FocusSession]) -> String {
        func quote(_ s: String) -> String { let safe = s.first.map { "=+-@\t\r".contains($0) } == true ? "'" + s : s; return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        let iso = ISO8601DateFormatter()
        return "id,intention,kind,status,start_utc,end_utc,active_seconds,paused_seconds,project_id,recovery_note,segment_contexts_json\n" + sessions.filter { $0.deletedAt == nil }.map { s in
            [s.id.uuidString, s.intention, s.kind.rawValue, s.status.rawValue, iso.string(from: s.started), s.ended.map(iso.string) ?? "", String(s.active), String(s.paused), s.projectID?.uuidString ?? "", s.recoveryNote ?? "", String(data: (try? JSONEncoder().encode(s.segments)) ?? Data(), encoding: .utf8) ?? ""].map(quote).joined(separator: ",")
        }.joined(separator: "\n")
    }
    public static func markdown(_ archive: Archive) -> String {
        "# Tempo report\n\nDurations exclude pauses. Breaks are separate. Recovered durations may be estimated.\n\n" + archive.sessions.filter { $0.deletedAt == nil }.map { "- \($0.started.formatted()): \($0.kind.label), \(Int($0.active / 60)) minutes — \($0.intention.replacingOccurrences(of: "\n", with: " ")) (\($0.status.rawValue))" }.joined(separator: "\n")
    }
}
