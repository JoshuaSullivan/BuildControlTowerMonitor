import SwiftUI

/// Streamed stdout/stderr from the most recently run daemon action, auto-
/// scrolling to the newest line as it streams in.
struct DaemonOutputLogView: View {
    /// The lines to display, oldest first.
    let lines: [SubprocessRunner.OutputLine]

    /// Cap on the log's height so a long install scrolls instead of growing
    /// the widget off the bottom of the screen, mirroring
    /// `MenuContentView`'s waiting-list height cap.
    private static let maxHeight: CGFloat = 200

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(lines.enumerated(), id: \.offset) { _, line in
                    Text(line.text)
                        .foregroundStyle(line.stream == .standardError ? .red : .primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .defaultScrollAnchor(.bottom)
        .font(.system(.caption, design: .monospaced))
        .frame(maxHeight: Self.maxHeight)
        .padding(6)
        .background(.quaternary.opacity(0.3), in: .rect(cornerRadius: 6))
    }
}
