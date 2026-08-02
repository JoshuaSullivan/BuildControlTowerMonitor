import Foundation
import Testing
@testable import BuildControlTowerMonitor

/// Tests decoding of the daemon's `/config` payload, including the partial and
/// missing cases a monitor hits when pointed at an older daemon.
struct DaemonConfigDecodingTests {
    private func decode(_ json: String) throws -> DaemonConfig {
        try JSONDecoder().decode(DaemonConfig.self, from: Data(json.utf8))
    }

    @Test func decodesTheDocumentedPayload() throws {
        let config = try decode(#"""
        {
          "version": "0.3.0",
          "port": 7373,
          "pollSeconds": 120,
          "staleGrantGraceSeconds": 360,
          "recommendedHeartbeatSeconds": 120,
          "cpuThresholdPercent": 40
        }
        """#)

        #expect(config.version == "0.3.0")
        #expect(config.pollSeconds == 120)
        #expect(config.staleGrantGraceSeconds == 360)
        #expect(config.recommendedHeartbeatSeconds == 120)
    }

    @Test func decodesARetunedDaemon() throws {
        let config = try decode(#"""
        {"version":"0.3.0","pollSeconds":10,"staleGrantGraceSeconds":90,"recommendedHeartbeatSeconds":30}
        """#)

        #expect(config.staleGrantGraceSeconds == 90)
        #expect(config.recommendedHeartbeatSeconds == 30)
    }

    @Test func missingFieldsFallBackIndividually() throws {
        // A field the monitor doesn't recognise being absent must not discard
        // the ones that are present.
        let config = try decode(#"{"staleGrantGraceSeconds":90}"#)

        #expect(config.staleGrantGraceSeconds == 90)
        #expect(config.recommendedHeartbeatSeconds == DaemonConfig.fallback.recommendedHeartbeatSeconds)
        #expect(config.pollSeconds == DaemonConfig.fallback.pollSeconds)
        #expect(config.version == nil)
    }

    @Test func emptyObjectDecodesToTheDefaults() throws {
        #expect(try decode("{}") == DaemonConfig.fallback)
    }

    @Test func fallbackMatchesTheDocumentedDefaults() {
        // These mirror the daemon's Configuration.default. If the daemon's
        // defaults change, a monitor talking to a pre-0.3.0 build would silently
        // judge against the wrong numbers.
        #expect(DaemonConfig.fallback.pollSeconds == 120)
        #expect(DaemonConfig.fallback.staleGrantGraceSeconds == 360)
        #expect(DaemonConfig.fallback.recommendedHeartbeatSeconds == 120)
    }

    @Test func throwsOnMalformedJSON() {
        #expect(throws: (any Error).self) {
            _ = try decode("not json")
        }
    }
}
