import Foundation
import Testing
@testable import BuildControlTowerMonitor

/// Tests the menu-bar label's composition rules. These matter more than they
/// look: the status item sits in a shared strip, so a label that changes width
/// shifts every icon to its left.
struct MenuBarLabelContentTests {
    private func active(progress: Int?, elapsed: Int = 90) -> StatusDTO.ActiveEntry {
        .init(
            id: UUID(),
            agent: "claude-A",
            task: "xcodebuild",
            progress: progress,
            elapsedSeconds: elapsed,
            secondsSinceHeartbeat: 5
        )
    }

    private func waiting() -> StatusDTO.WaitingEntry {
        .init(id: UUID(), agent: "claude-B", task: "swift test", waitingSeconds: 30)
    }

    private func content(_ snapshot: StatusDTO?) -> MenuBarLabelContent {
        MenuBarLabelContent(state: .derive(from: snapshot), snapshot: snapshot)
    }

    @Test func reportedProgressFillsTheSlot() {
        let label = content(StatusDTO(active: active(progress: 45), waiting: []))

        #expect(label.anchorSymbolName == "hammer.fill")
        #expect(label.modifierSymbolName == nil)
        #expect(label.slotText?.contains("45") == true)
    }

    @Test func slotFallsBackToElapsedWhenNoEstimateReported() {
        // Plenty of agents never report progress, so this is the common case,
        // not an edge one — and it is exactly when the label must still say
        // something rather than collapsing to a bare glyph.
        let label = content(StatusDTO(active: active(progress: nil, elapsed: 90), waiting: []))

        #expect(label.modifierSymbolName == nil)
        let slotText = label.slotText ?? ""
        #expect(!slotText.isEmpty)
        #expect(!slotText.contains("%"))
    }

    @Test func slotIsAlwaysOccupied() {
        // Either text or a glyph, in every state — never neither.
        let snapshots: [StatusDTO?] = [
            nil,
            StatusDTO(active: nil, waiting: []),
            StatusDTO(active: nil, waiting: [waiting()]),
            StatusDTO(active: active(progress: 45), waiting: []),
            StatusDTO(active: active(progress: nil), waiting: []),
        ]

        for snapshot in snapshots {
            let label = content(snapshot)
            #expect(label.slotText != nil || label.modifierSymbolName != nil)
        }
    }

    @Test func zeroProgressIsShownRatherThanTreatedAsUnreported() {
        // `progress: 0` is a real report and must not fall through to elapsed.
        let label = content(StatusDTO(active: active(progress: 0), waiting: []))
        #expect(label.slotText?.contains("0") == true)
        #expect(label.slotText?.contains("%") == true)
    }

    @Test func depthBadgeAppearsOnlyBeyondOneBuild() {
        let alone = content(StatusDTO(active: active(progress: 45), waiting: []))
        let queued = content(StatusDTO(active: active(progress: 45), waiting: [waiting()]))
        let blocked = content(StatusDTO(active: nil, waiting: [waiting()]))
        let twoBlocked = content(StatusDTO(active: nil, waiting: [waiting(), waiting()]))

        #expect(alone.depthBadge == nil)
        #expect(queued.depthBadge == "2")
        #expect(blocked.depthBadge == nil)
        #expect(twoBlocked.depthBadge == "2")
    }

    @Test func nonBuildingStatesUseTheirGlyphAndNoText() {
        let idle = content(StatusDTO(active: nil, waiting: []))
        let blocked = content(StatusDTO(active: nil, waiting: [waiting()]))
        let offline = content(nil)

        #expect(idle.modifierSymbolName == "zzz")
        #expect(idle.slotText == nil)
        #expect(blocked.modifierSymbolName == "pause.circle")
        #expect(blocked.slotText == nil)
        #expect(offline.modifierSymbolName == "exclamationmark.triangle")
        #expect(offline.slotText == nil)
    }

    @Test func everyStateKeepsTheHammerAnchor() {
        // The anchor is the app's identity in a crowded menu bar; offline is
        // anchored too, so the item never becomes an unattributed warning sign.
        let snapshots: [StatusDTO?] = [
            nil,
            StatusDTO(active: nil, waiting: []),
            StatusDTO(active: nil, waiting: [waiting()]),
            StatusDTO(active: active(progress: 45), waiting: []),
        ]

        for snapshot in snapshots {
            #expect(content(snapshot).anchorSymbolName.hasPrefix("hammer"))
        }
    }

    @Test func accessibilityLabelNamesTheState() {
        let building = content(StatusDTO(active: active(progress: 45), waiting: [waiting()]))
        #expect(building.accessibilityLabel.contains("Building"))
        #expect(building.accessibilityLabel.contains("45 percent"))
        #expect(building.accessibilityLabel.contains("2 in queue"))

        #expect(content(nil).accessibilityLabel.contains("Offline"))
        #expect(content(StatusDTO(active: nil, waiting: [waiting()])).accessibilityLabel.contains("Blocked"))
    }
}
