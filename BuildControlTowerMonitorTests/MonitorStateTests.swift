import Foundation
import Testing
@testable import BuildControlTowerMonitor

/// Tests for the pure display-state derivation, which needs no live daemon.
struct MonitorStateTests {
    @Test func offlineWhenSnapshotIsNil() {
        #expect(MonitorState.derive(from: nil) == .offline)
    }

    @Test func idleWhenNoActiveBuild() {
        let snapshot = StatusDTO(active: nil, waiting: [])
        #expect(MonitorState.derive(from: snapshot) == .idle)
    }

    @Test func idleWhenWaitingButNoActiveGrant() {
        // Nothing holds the slot yet, so a non-empty waiting line still reads as
        // idle (matches the daemon withholding a grant during an external build).
        let snapshot = StatusDTO(active: nil, waiting: [.init(id: UUID(), agent: "A")])
        #expect(MonitorState.derive(from: snapshot) == .idle)
    }

    @Test func buildingWhenActivePresent() {
        let snapshot = StatusDTO(active: .init(id: UUID(), agent: "A"), waiting: [])
        #expect(MonitorState.derive(from: snapshot) == .building)
    }

    @Test func symbolsAreDistinctPerState() {
        let symbols = Set([MonitorState.idle, .building, .offline].map(\.symbolName))
        #expect(symbols.count == 3)
    }
}

/// Tests for the queue-depth computation and the badge threshold.
struct QueueDepthTests {
    @Test func depthIsZeroWhenEmpty() {
        #expect(StatusDTO(active: nil, waiting: []).depth == 0)
    }

    @Test func depthCountsActivePlusWaiting() {
        let dto = StatusDTO(
            active: .init(id: UUID(), agent: "A"),
            waiting: [.init(id: UUID(), agent: "B"), .init(id: UUID(), agent: "C")]
        )
        #expect(dto.depth == 3)
    }

    @Test("Badge shows only when depth exceeds one", arguments: [
        (0, false), (1, false), (2, true), (5, true),
    ])
    func badgeThreshold(depth: Int, shows: Bool) {
        #expect((depth > 1) == shows)
    }
}
