import Foundation

/// Persists the on-disk location of the `build-control-tower` repository the
/// daemon control widget operates on.
///
/// The Monitor app is unsandboxed, so this is a plain absolute path string in
/// `UserDefaults` — no security-scoped bookmark is needed. Mirrors
/// ``MonitorConfiguration``'s persistence pattern.
nonisolated struct ControlTowerRepositoryConfiguration: Sendable {
    /// `UserDefaults` key holding the repository's absolute path.
    static let repoPathDefaultsKey = "BCTRepoPath"

    /// The configured repository path, or `nil` if none has been chosen yet.
    let path: URL?

    /// Read the currently persisted path.
    ///
    /// - Parameter defaults: injectable for testing.
    init(defaults: UserDefaults = .standard) {
        if let raw = defaults.string(forKey: Self.repoPathDefaultsKey) {
            path = URL(fileURLWithPath: raw)
        } else {
            path = nil
        }
    }

    /// Persist a newly chosen repository path.
    static func persist(_ path: URL, defaults: UserDefaults = .standard) {
        defaults.set(path.path, forKey: repoPathDefaultsKey)
    }

    /// Clear the persisted path, e.g. before re-prompting via "Relocate…".
    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: repoPathDefaultsKey)
    }
}
