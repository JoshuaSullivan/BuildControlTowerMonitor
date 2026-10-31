import SwiftUI

struct WaitingBuildListView: View {
    let entries: [StatusDTO.WaitingEntry]

    private static let maxHeight: CGFloat = 160

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Waiting (\(entries.count))")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entries.enumerated(), id: \.element.id) { index, entry in
                        WaitingBuildRowView(position: index + 1, entry: entry)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: Self.maxHeight)
        }
        // MenuBarExtra can propose a compressed height while sizing its panel.
        .fixedSize(horizontal: false, vertical: true)
    }
}
