import Testing
@testable import BuildControlTowerMonitor

/// Tests the plist-presence + registration + HTTP-reachability truth table.
struct DaemonAvailabilityResolverTests {
    @Test func noPlistIsNotInstalledRegardlessOfOtherSignals() {
        #expect(
            DaemonAvailabilityResolver.resolve(isPlistInstalled: false, isRegistered: false, httpReachable: false)
                == .notInstalled
        )
        #expect(
            DaemonAvailabilityResolver.resolve(isPlistInstalled: false, isRegistered: true, httpReachable: true)
                == .notInstalled
        )
        #expect(
            DaemonAvailabilityResolver.resolve(isPlistInstalled: false, isRegistered: nil, httpReachable: false)
                == .notInstalled
        )
    }

    @Test func plistWithoutRegistrationIsStopped() {
        #expect(
            DaemonAvailabilityResolver.resolve(isPlistInstalled: true, isRegistered: false, httpReachable: false)
                == .installedStopped
        )
    }

    @Test func plistRegisteredButUnreachableIsStopped() {
        #expect(
            DaemonAvailabilityResolver.resolve(isPlistInstalled: true, isRegistered: true, httpReachable: false)
                == .installedStopped
        )
    }

    @Test func plistRegisteredAndReachableIsRunning() {
        #expect(
            DaemonAvailabilityResolver.resolve(isPlistInstalled: true, isRegistered: true, httpReachable: true)
                == .installedRunning
        )
    }

    @Test func unknownWhenRegistrationCheckFailsDespitePlistPresent() {
        #expect(
            DaemonAvailabilityResolver.resolve(isPlistInstalled: true, isRegistered: nil, httpReachable: true)
                == .unknown
        )
        #expect(
            DaemonAvailabilityResolver.resolve(isPlistInstalled: true, isRegistered: nil, httpReachable: false)
                == .unknown
        )
    }
}
