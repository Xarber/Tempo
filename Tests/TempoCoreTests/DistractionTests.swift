// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import Testing
@testable import TempoCore
struct DistractionTests {
    @Test(arguments: ["https://example.com", "example.com/path", "example.com:443", "127.0.0.1", "localhost", "*.com", "evil..com", "-bad.com", "éxample.com", "example.1com"])
    func rejectsUnsafeDomain(value: String) { #expect(DomainPolicy.normalize(value) == nil) }
    @Test func normalizeAndDeduplicate() {
        #expect(DomainPolicy.normalize(" *.Example.COM ") == "example.com")
    }
    @Test func browserLeaseRequiresOptInAndActiveFocus() throws {
        let wall = Date(timeIntervalSince1970: 1000)
        var timer = TimerEngine(); try timer.start(duration: 600, intention: "Private intention", wall: wall, monotonic: 0)
        var settings = Settings(); settings.websiteDomains = ["example.com"]
        #expect(!BrowserPolicy(session: timer.session, settings: settings, remaining: 600, wall: wall).enabled)
        settings.websiteBlockingEnabled = true
        let policy = BrowserPolicy(session: timer.session, settings: settings, remaining: 600, wall: wall)
        #expect(policy.enabled); #expect(policy.expiresAt == 1030)
        #expect(!String(decoding: try JSONEncoder().encode(policy), as: UTF8.self).contains("Private intention"))
        try timer.pause(wall: wall, monotonic: 0)
        #expect(!BrowserPolicy(session: timer.session, settings: settings, remaining: 600, wall: wall).enabled)
        var breakTimer = TimerEngine(); try breakTimer.start(kind: .shortBreak, duration: 300, intention: "Rest", wall: wall, monotonic: 0)
        #expect(!BrowserPolicy(session: breakTimer.session, settings: settings, remaining: 300, wall: wall).enabled)
    }
    @Test func simulatedExportsCannotEnterRecordedHistory() throws {
        var qa = Archive(); qa.provenance = .simulated
        #expect(throws: TempoError.self) { try Portability.merge(qa, into: Archive()) }
        #expect(try Portability.merge(qa, into: qa).provenance == .simulated)
    }
    @Test func oldSettingsDecodeWithoutNewCapabilities() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(Archive())
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let restored = try Portability.decode(JSONSerialization.data(withJSONObject: object))
        #expect(restored.settings.websiteDomains == nil)
        #expect(restored.settings.websiteBlockingEnabled == nil)
    }
}
