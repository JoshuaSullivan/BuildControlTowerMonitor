import Foundation

/// The daemon control widget's view of whether the daemon is installed and
/// running, combining three independent signals: whether the LaunchAgent
/// plist exists on disk, `launchctl` registration, and HTTP reachability.
nonisolated enum DaemonAvailability: Sendable, Equatable {
    /// No LaunchAgent plist exists — `build.sh --install-agent` has never run
    /// (or `--uninstall-agent` removed it).
    case notInstalled
    /// The plist exists, but the job isn't currently registered/running.
    case installedStopped
    /// The plist exists, the job is registered, and the daemon answers HTTP.
    case installedRunning
    /// The registration check itself couldn't be run (e.g. `launchctl` missing).
    case unknown
}

/// Resolves ``DaemonAvailability`` from three signals: whether the
/// LaunchAgent plist is present on disk, a `launchctl print` registration
/// check, and the Monitor's existing `/status` HTTP-reachability signal.
///
/// The plist's presence, not registration, is the "installed" signal:
/// `launchctl bootout` (``DaemonAction/stop``) fully de-registers the job
/// rather than merely pausing it, so a stopped-but-still-installed daemon and
/// a never-installed one look identical to a registration check alone — only
/// the plist (removed solely by `--uninstall-agent`) tells them apart.
nonisolated enum DaemonAvailabilityResolver {
    /// - Parameters:
    ///   - isPlistInstalled: whether the daemon's LaunchAgent plist exists on
    ///     disk.
    ///   - isRegistered: the result of the `launchctl print` exit-code check,
    ///     or `nil` if that check itself failed to run.
    ///   - httpReachable: `true` when `BuildStatusModel.state != .offline`.
    static func resolve(isPlistInstalled: Bool, isRegistered: Bool?, httpReachable: Bool) -> DaemonAvailability {
        guard isPlistInstalled else { return .notInstalled }
        guard let isRegistered else { return .unknown }
        return (isRegistered && httpReachable) ? .installedRunning : .installedStopped
    }
}
