import Foundation
import Testing
@testable import BuildControlTowerMonitor

/// Tests persistence of the control-tower repository path.
struct ControlTowerRepositoryConfigurationTests {
    private func makeDefaults() throws -> UserDefaults {
        let suite = "test-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func unsetByDefault() throws {
        let config = ControlTowerRepositoryConfiguration(defaults: try makeDefaults())
        #expect(config.path == nil)
    }

    @Test func persistsAndReadsBack() throws {
        let defaults = try makeDefaults()
        let path = URL(fileURLWithPath: "/tmp/build-control-tower")
        ControlTowerRepositoryConfiguration.persist(path, defaults: defaults)
        #expect(ControlTowerRepositoryConfiguration(defaults: defaults).path == path)
    }

    @Test func clearRemovesThePath() throws {
        let defaults = try makeDefaults()
        ControlTowerRepositoryConfiguration.persist(URL(fileURLWithPath: "/tmp/x"), defaults: defaults)
        ControlTowerRepositoryConfiguration.clear(defaults: defaults)
        #expect(ControlTowerRepositoryConfiguration(defaults: defaults).path == nil)
    }
}
