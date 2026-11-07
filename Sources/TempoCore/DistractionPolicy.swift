// SPDX-License-Identifier: AGPL-3.0-only
import Foundation

public struct DistractionProfile: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name: String
    public var domains: [String]
    public var applicationIDs: [String]
    public init(name: String, domains: [String] = [], applicationIDs: [String] = []) {
        self.name = name; self.domains = domains; self.applicationIDs = applicationIDs
    }
}
public enum DomainPolicy {
    /// ASCII DNS names only. A rule includes subdomains; paths/schemes/ports are never accepted.
    public static func normalize(_ value: String) -> String? {
        var domain = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if domain.hasPrefix("*.") { domain.removeFirst(2) }
        guard domain.count <= 253, domain.utf8.allSatisfy({ $0 < 128 }) else { return nil }
        let labels = domain.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= 2, labels.allSatisfy({ label in
            !label.isEmpty && label.count <= 63 && label.first != "-" && label.last != "-" && label.utf8.allSatisfy { (97...122).contains($0) || (48...57).contains($0) || $0 == 45 }
        }), let last = labels.last, last.first?.isLetter == true else { return nil }
        return domain
    }
}
public struct BrowserPolicy: Codable, Equatable, Sendable {
    public var schemaVersion = 1
    public var enabled: Bool
    public var sessionID: String?
    public var expiresAt: Double
    public var domains: [String]
    public init(session: FocusSession?, settings: Settings, remaining: Double?, wall: Date) {
        enabled = settings.websiteBlockingEnabled == true && session?.status == .running && session?.kind.isFocus == true
        sessionID = enabled ? session?.id.uuidString : nil
        expiresAt = wall.timeIntervalSince1970 + (enabled ? min(30, max(0, remaining ?? 30)) : 0)
        domains = enabled ? Array(Set((settings.websiteDomains ?? []).compactMap(DomainPolicy.normalize))).sorted() : []
    }
}
