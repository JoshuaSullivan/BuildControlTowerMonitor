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

    /// Owns daemon install/start/stop/uninstall state at the app level so an
    /// in-flight action survives the Daemon Control window being closed and
    /// reopened.
    @State private var daemonControlModel = DaemonControlModel()

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

        // Auxiliary panels get real windows, not popover content: a daemon
        // install can run for tens of seconds and must survive the user
        // clicking elsewhere, which a MenuBarExtra(.window) popover cannot do.
        Window("Daemon Control", id: WindowID.daemonControl) {
            DaemonControlWidgetView()
                .environment(model)
                .environment(daemonControlModel)
        }
        .windowResizability(.contentSize)

        Window("About", id: WindowID.about) {
            AboutWidgetView()
        }
        .windowResizability(.contentSize)
    }
}

/// Identifiers for the app's auxiliary `Window` scenes, shared between
/// `BuildControlTowerMonitorApp` and the buttons that call `openWindow(id:)`.
enum WindowID {
    static let daemonControl = "daemon-control"
    static let about = "about"
}
