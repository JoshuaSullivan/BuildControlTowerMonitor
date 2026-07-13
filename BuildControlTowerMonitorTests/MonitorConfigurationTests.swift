import Foundation
import Testing
@testable import BuildControlTowerMonitor

/// Tests the daemon-port resolution precedence and the base-URL construction.
struct MonitorConfigurationTests {
    private func makeDefaults() throws -> UserDefaults {
        let suite = "test-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func defaultsToStandardPort() throws {
        let port = MonitorConfiguration.resolvePort(defaults: try makeDefaults(), environment: [:])
        #expect(port == 7373)
    }

    @Test func environmentOverridesDefault() throws {
        let port = MonitorConfiguration.resolvePort(
            defaults: try makeDefaults(),
            environment: ["BCT_PORT": "8080"]
        )
        #expect(port == 8080)
    }

    @Test func userDefaultsWinsOverEnvironment() throws {
        let defaults = try makeDefaults()
        defaults.set(9000, forKey: MonitorConfiguration.portDefaultsKey)
        let port = MonitorConfiguration.resolvePort(
            defaults: defaults,
            environment: ["BCT_PORT": "8080"]
        )
        #expect(port == 9000)
    }

    @Test func invalidEnvironmentFallsBackToDefault() throws {
        let port = MonitorConfiguration.resolvePort(
            defaults: try makeDefaults(),
            environment: ["BCT_PORT": "not-a-number"]
        )
        #expect(port == 7373)
    }

    @Test func outOfRangePortIsRejected() throws {
        let port = MonitorConfiguration.resolvePort(
            defaults: try makeDefaults(),
            environment: ["BCT_PORT": "70000"]
        )
        #expect(port == 7373)
    }

    @Test func baseURLReflectsResolvedPort() {
        let config = MonitorConfiguration(port: 7399)
        #expect(config.baseURL.absoluteString == "http://127.0.0.1:7399")
    }
}
