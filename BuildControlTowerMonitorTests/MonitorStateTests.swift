import Foundation
import Testing
@testable import BuildControlTowerMonitor

/// Tests for the pure display-state derivation, which needs no live daemon.
struct MonitorStateTests {
    private func active(progress: Int? = nil) -> StatusDTO.ActiveEntry {
        .init(
            id: UUID(),
            agent: "A",
            task: "build",
            progress: progress,
            elapsedSeconds: 30,
            secondsSinceHeartbeat: 5
        )
    }

    private func waiting() -> StatusDTO.WaitingEntry {
        .init(id: UUID(), agent: "B", task: "test", waitingSeconds: 10)
    }

    @Test func offlineWhenSnapshotIsNil() {
        #expect(MonitorState.derive(from: nil) == .offline)
    }

    @Test func idleWhenQueueIsEmpty() {
        #expect(MonitorState.derive(from: StatusDTO(active: nil, waiting: [])) == .idle)
    }

    @Test func blockedWhenWaitingButNoActiveGrant() {
        // The daemon advances the queue unless its probe sees a build already
        // running, so a waiting line with no grant means something outside the
        // tower — typically a manual ⌘B — is holding the CPU. That is worth
        // distinguishing from a genuinely quiet machine.
        let snapshot = StatusDTO(active: nil, waiting: [waiting()])
        #expect(MonitorState.derive(from: snapshot) == .blocked)
    }

    @Test func buildingWhenActivePresent() {
        #expect(MonitorState.derive(from: StatusDTO(active: active(), waiting: [])) == .building)
    }

    @Test func buildingEvenWithOthersWaiting() {
        let snapshot = StatusDTO(active: active(), waiting: [waiting(), waiting()])
        #expect(MonitorState.derive(from: snapshot) == .building)
    }

    @Test func everyStateIsVisuallyDistinct() {
        // The anchor alone cannot carry state — `hammer` and `hammer.fill` are
        // near-identical as menu-bar templates — so distinctness must hold on
        // the anchor/modifier pair taken together.
        let pairs = MonitorState.allCases.map { "\($0.anchorSymbolName)+\($0.modifierSymbolName ?? "text")" }
        #expect(Set(pairs).count == MonitorState.allCases.count)
    }

    @Test func onlyBuildingLeavesTheSlotForText() {
        // Building surrenders the modifier position to the numeric slot; every
        // other state must fill it with a glyph so the width stays constant.
        for state in MonitorState.allCases {
            #expect((state.modifierSymbolName == nil) == (state == .building))
        }
    }
}

/// Tests for the queue-depth computation.
struct QueueDepthTests {
    @Test func depthIsZeroWhenEmpty() {
        #expect(StatusDTO(active: nil, waiting: []).depth == 0)
    }

    @Test func depthCountsActivePlusWaiting() {
        let dto = StatusDTO(
            active: .init(
                id: UUID(),
                agent: "A",
                task: nil,
                progress: nil,
                elapsedSeconds: 0,
                secondsSinceHeartbeat: 0
            ),
            waiting: [
                .init(id: UUID(), agent: "B", task: nil, waitingSeconds: 0),
                .init(id: UUID(), agent: "C", task: nil, waitingSeconds: 0),
            ]
        )
        #expect(dto.depth == 3)
    }
}
