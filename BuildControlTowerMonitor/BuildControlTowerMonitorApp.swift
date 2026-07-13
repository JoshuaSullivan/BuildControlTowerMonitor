import SwiftUI

/// The menu-bar-only monitor app.
///
/// Declares a single `MenuBarExtra` scene whose label reflects the daemon's
/// state (and a queue-depth badge) and whose window lists the active and
/// waiting builds. The app runs as an agent (`LSUIElement`), so it has no dock
/// icon and no default window.
@main
struct BuildControlTowerMonitorApp: App {
    /// The shared model, owned here and injected into the panel.
    @State private var model = BuildStatusModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environment(model)
        } label: {
            // The label owns the poll loop: it is always present, whereas the
            // panel content only exists while the menu is open.
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
