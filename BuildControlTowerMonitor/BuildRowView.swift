import SwiftUI

/// One row in the queue panel: an optional 1-based waiting position and the
/// agent name. The active build passes `position: nil` and gets a hammer glyph
/// instead of a number.
struct BuildRowView: View {
    /// The 1-based waiting position, or `nil` for the active build.
    let position: Int?

    /// The build entry to display.
    let entry: StatusDTO.Entry

    var body: some View {
        HStack(spacing: 6) {
            if let position {
                Text(position, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 16, alignment: .trailing)
            } else {
                Image(systemName: "hammer.fill")
                    .foregroundStyle(.secondary)
            }
            Text(entry.agent ?? "unnamed agent")
            Spacer(minLength: 0)
        }
    }
}
