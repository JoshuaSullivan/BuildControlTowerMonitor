import Foundation

/// What the menu-bar status item should draw, computed as pure data so the
/// rules can be tested without instantiating a view.
///
/// The layout is a constant anchor glyph followed by one variable slot. While
/// building the slot holds text (progress, or elapsed time when no estimate was
/// reported); otherwise it holds a state glyph. Keeping the slot always
/// occupied is deliberate — a label that changes width shifts every icon to its
/// left in the menu bar.
nonisolated struct MenuBarLabelContent: Equatable, Sendable {
    /// The constant app glyph.
    let anchorSymbolName: String

    /// The state glyph, when the slot isn't showing text.
    let modifierSymbolName: String?

    /// The numeric slot's text, shown while building.
    let slotText: String?

    /// The queue-depth badge, shown only when more than one build is in the
    /// system — a lone build needs no count.
    let depthBadge: String?

    /// A spoken description of the whole item for VoiceOver.
    let accessibilityLabel: String

    /// Compose the label for a state and the snapshot it came from.
    ///
    /// - Parameters:
    ///   - state: the display state.
    ///   - snapshot: the snapshot the state was derived from, or `nil` when
    ///     offline.
    init(state: MonitorState, snapshot: StatusDTO?) {
        anchorSymbolName = state.anchorSymbolName
        modifierSymbolName = state.modifierSymbolName

        let active = state == .building ? snapshot?.active : nil
        slotText = active.map(Self.slotText)

        let depth = snapshot?.depth ?? 0
        depthBadge = depth > 1 ? "\(depth)" : nil

        accessibilityLabel = Self.accessibilityLabel(state: state, active: active, depth: depth)
    }

    /// The active build's headline number: its own estimate when it reported
    /// one, and otherwise how long it has been running — which the daemon always
    /// sends, so the slot is never empty.
    private static func slotText(for active: StatusDTO.ActiveEntry) -> String {
        guard let progress = active.progress else {
            return active.elapsedSeconds.buildAgeDescription
        }
        return (Double(progress) / 100).formatted(.percent.precision(.fractionLength(0)))
    }

    private static func accessibilityLabel(
        state: MonitorState,
        active: StatusDTO.ActiveEntry?,
        depth: Int
    ) -> String {
        var parts = [state.label]
        if let active {
            if let progress = active.progress {
                parts.append("\(progress) percent")
            }
            parts.append("\(active.elapsedSeconds.buildAgeDescription) elapsed")
        }
        if depth > 1 {
            parts.append("\(depth) in queue")
        }
        return parts.joined(separator: ", ")
    }
}
