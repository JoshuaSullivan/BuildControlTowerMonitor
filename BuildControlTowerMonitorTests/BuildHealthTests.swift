import Foundation
import Testing
@testable import BuildControlTowerMonitor

/// Tests that check-in staleness is judged against the daemon's own thresholds
/// rather than assumed ones — the reason `/config` exists at all.
struct BuildHealthTests {
    private let defaults = DaemonConfig.fallback

    @Test func recentCheckInIsFresh() {
        #expect(.evaluate(secondsSinceHeartbeat: 0, config: defaults) == BuildHealth.fresh)
        #expect(.evaluate(secondsSinceHeartbeat: 119, config: defaults) == BuildHealth.fresh)
    }

    @Test func cadenceBoundaryTipsToQuiet() {
        // At exactly the recommended cadence the agent is due, not overdue by a
        // margin — but it has stopped keeping pace, which is the early signal.
        #expect(.evaluate(secondsSinceHeartbeat: 120, config: defaults) == BuildHealth.quiet)
        #expect(.evaluate(secondsSinceHeartbeat: 359, config: defaults) == BuildHealth.quiet)
    }

    @Test func graceBoundaryTipsToStale() {
        // At the grace window the daemon *may* reclaim — only if its probe also
        // sees no build CPU, which is why this is a prompt to look rather than a
        // verdict that the agent is gone.
        #expect(.evaluate(secondsSinceHeartbeat: 360, config: defaults) == BuildHealth.stale)
        #expect(.evaluate(secondsSinceHeartbeat: 5_000, config: defaults) == BuildHealth.stale)
    }

    @Test func thresholdsFollowARetunedDaemon() {
        // A daemon launched with BCT_GRACE_SECONDS=90 reclaims six times sooner
        // than the default. Silence of 100s is stale there and merely fresh
        // under the defaults — the whole point of asking the daemon.
        let retuned = DaemonConfig(
            version: "0.3.0",
            pollSeconds: 10,
            staleGrantGraceSeconds: 90,
            recommendedHeartbeatSeconds: 30
        )

        #expect(.evaluate(secondsSinceHeartbeat: 100, config: retuned) == BuildHealth.stale)
        #expect(.evaluate(secondsSinceHeartbeat: 100, config: defaults) == BuildHealth.fresh)
        #expect(.evaluate(secondsSinceHeartbeat: 40, config: retuned) == BuildHealth.quiet)
    }

    @Test func onlyFreshNeedsNoExplanation() {
        #expect(BuildHealth.fresh.warrantsExplanation == false)
        #expect(BuildHealth.quiet.warrantsExplanation)
        #expect(BuildHealth.stale.warrantsExplanation)
    }

    @Test func tiersAreDistinguishableWithoutColor() {
        // Colour is a secondary cue; the symbol must carry the tier on its own.
        let symbols = Set(BuildHealth.allCases.map(\.symbolName))
        #expect(symbols.count == BuildHealth.allCases.count)
    }
}
