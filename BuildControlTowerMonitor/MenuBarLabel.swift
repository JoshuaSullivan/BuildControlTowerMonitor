import SwiftUI

/// The menu-bar status item's label: a state icon plus a depth badge when more
/// than one build is in the system.
///
/// This view also hosts the app-lifetime polling task. The label is always
/// present in the status bar, so its `.task` starts at launch and is cancelled
/// only when the app terminates — unlike the panel content, which exists only
/// while the menu is open.
struct MenuBarLabel: View {
    /// The model driving both the displayed state and the poll loop.
    let model: BuildStatusModel

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: model.state.symbolName)
            if model.depth > 1 {
                Text(model.depth, format: .number)
            }
        }
        .task { await model.pollLoop() }
    }
}
