import AppKit
import SwiftUI
import Testing
@testable import BuildControlTowerMonitor

@MainActor
struct WaitingBuildListViewTests {
    @Test(arguments: [1, 2, 6, 20], [0.0, 1_000.0])
    func waitingListFitsItsRowsUpToTheScrollLimit(count: Int, proposedHeight: CGFloat) {
        let entries = (1...count).map { index in
            StatusDTO.WaitingEntry(
                id: UUID(),
                agent: "Agent \(index)",
                task: "Build",
                waitingSeconds: 30
            )
        }
        let rowHeight = height(of: WaitingBuildRowView(position: 1, entry: entries[0]))
        let headingHeight = height(of: Text("Waiting (\(count))").font(.caption))
        let expectedHeight = headingHeight + 4 + min(
            CGFloat(count) * rowHeight + CGFloat(count - 1) * 4,
            160
        )
        let actualHeight = height(
            of: WaitingBuildListView(entries: entries),
            proposedHeight: proposedHeight
        )

        #expect(abs(actualHeight - expectedHeight) < 1)
    }

    private func height<Content: View>(
        of content: Content,
        proposedHeight: CGFloat = 1_000
    ) -> CGFloat {
        let host = NSHostingController(rootView: content.frame(width: 296))
        return host.sizeThatFits(in: CGSize(width: 296, height: proposedHeight)).height
    }
}
