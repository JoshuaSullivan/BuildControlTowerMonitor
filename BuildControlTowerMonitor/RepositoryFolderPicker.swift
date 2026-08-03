import AppKit

/// Prompts the user to locate the `build-control-tower` repository folder,
/// validates the choice, and persists it.
///
/// Used identically for the first-use prompt (triggered by any daemon action
/// while no path is configured) and the standalone "Relocate…" button, so the
/// two entry points never diverge in behavior.
@MainActor
enum RepositoryFolderPicker {
    /// Show the folder picker, validate the selection, and persist it on
    /// success.
    ///
    /// - Returns: the chosen, validated path, or `nil` if the user cancelled
    ///   or the chosen folder failed validation (an alert explains why before
    ///   this returns).
    static func presentAndPersist() -> URL? {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Select the build-control-tower repository folder (the one containing build.sh)."

        guard panel.runModal() == .OK, let chosen = panel.url else { return nil }

        let result = RepositoryValidator.validate(path: chosen)
        guard result == .valid else {
            presentValidationAlert(reason: result.reason)
            return nil
        }

        ControlTowerRepositoryConfiguration.persist(chosen)
        return chosen
    }

    private static func presentValidationAlert(reason: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "That doesn't look like build-control-tower"
        alert.informativeText = reason
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
