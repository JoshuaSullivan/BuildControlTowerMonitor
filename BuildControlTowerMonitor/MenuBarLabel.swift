import SwiftUI

/// The menu-bar status item's label: a constant hammer anchor, then either a
/// state glyph or the active build's headline number, plus a depth badge when
/// more than one build is in the system.
///
/// This view also hosts the app-lifetime polling task. The label is always
/// present in the status bar, so its `.task` starts at launch and is cancelled
/// only when the app terminates — unlike the panel content, which exists only
/// while the menu is open.
struct MenuBarLabel: View {
    /// The model driving both the displayed state and the poll loop.
    let model: BuildStatusModel

    /// Width reserved for the variable slot, so `5%`, `100%`, and `3m 20s` all
    /// occupy the same box. Without it the status item resizes as a build
    /// progresses, shifting every menu-bar icon to its left.
    private static let slotWidth: CGFloat = 34

    var body: some View {
        let content = MenuBarLabelContent(state: model.state, snapshot: model.snapshot)

        HStack(spacing: 3) {
            Image(systemName: content.anchorSymbolName)

            if let slotText = content.slotText {
                Text(slotText)
                    .monospacedDigit()
                    .frame(width: Self.slotWidth, alignment: .leading)
            } else if let modifierSymbolName = content.modifierSymbolName {
                // The modifier glyphs are optically heavier than the hammer at a
                // matched size, so they are scaled down to read as a badge on
                // the anchor rather than competing with it.
                Image(systemName: modifierSymbolName)
                    .imageScale(.small)
                    .frame(width: Self.slotWidth, alignment: .leading)
            }

            if let depthBadge = content.depthBadge {
                Text(depthBadge)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityLabel)
        .task { await model.pollLoop() }
    }
}
