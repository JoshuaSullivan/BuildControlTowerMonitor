import Testing
@testable import BuildControlTowerMonitor

/// Tests the pure comparison behind the daemon control widget's update check.
struct UpdateCheckerTests {
    @Test func upToDateWhenVersionsMatch() {
        #expect(UpdateChecker.evaluate(localVersion: "0.2.0", remoteTag: "v0.2.0") == .upToDate)
    }

    @Test func updateAvailableWhenRemoteIsNewer() {
        #expect(UpdateChecker.evaluate(localVersion: "0.2.0", remoteTag: "v0.3.0") == .updateAvailable(latest: "v0.3.0"))
    }

    @Test func upToDateWhenLocalIsAheadOfRemote() {
        #expect(UpdateChecker.evaluate(localVersion: "0.3.0", remoteTag: "v0.2.0") == .upToDate)
    }

    @Test func localVersionUnavailableWhenNilOrUnparseable() {
        #expect(UpdateChecker.evaluate(localVersion: nil, remoteTag: "v0.2.0") == .localVersionUnavailable)
        #expect(UpdateChecker.evaluate(localVersion: "not-a-version", remoteTag: "v0.2.0") == .localVersionUnavailable)
    }

    @Test func unknownWhenRemoteFetchFailed() {
        #expect(UpdateChecker.evaluate(localVersion: "0.2.0", remoteTag: nil) == .unknown)
        #expect(UpdateChecker.evaluate(localVersion: "0.2.0", remoteTag: "not-a-version") == .unknown)
    }
}
