import Foundation
import Observation

/// Observable state backing the daemon control widget: the configured repo
/// path, install/start/stop/uninstall progress, and the GitHub update check.
///
/// Owned at the app level (not window-scoped) so an in-flight action survives
/// the Daemon Control window being closed and reopened — the underlying
/// `build.sh`/`launchctl` process doesn't know or care whether its window is
/// visible, and cancelling on close would risk leaving launchd half-updated.
///
/// This target uses `MainActor` default actor isolation, so this
/// `@Observable` needs no explicit `@MainActor` annotation, matching
/// ``BuildStatusModel``.
@Observable
final class DaemonControlModel {
    /// The configured control-tower repository path, or `nil` if none has
    /// been chosen yet.
    private(set) var repoPath: URL?

    /// Whether the daemon is installed/running, per the last registration
    /// check combined with HTTP reachability.
    private(set) var availability: DaemonAvailability = .unknown

    /// The action currently running, if any. All four buttons disable while
    /// this is non-`nil`.
    private(set) var inFlightAction: DaemonAction?

    /// Streamed output from the most recently run action.
    private(set) var outputLog: [SubprocessRunner.OutputLine] = []

    /// A human-readable description of the most recent action's failure, if
    /// it failed.
    private(set) var lastError: String?

    /// The result of the most recent GitHub update check.
    private(set) var updateAvailability: UpdateAvailability = .unknown

    /// The subprocess launcher used for every daemon action.
    private let runner: SubprocessRunner

    /// The client used to check for a newer control-tower release.
    private let releaseClient: ControlTowerReleaseClient

    /// Create a model, reading any previously persisted repository path.
    init(runner: SubprocessRunner = SubprocessRunner(), releaseClient: ControlTowerReleaseClient = ControlTowerReleaseClient()) {
        self.runner = runner
        self.releaseClient = releaseClient
        self.repoPath = ControlTowerRepositoryConfiguration().path
    }

    /// Re-run the `launchctl` registration check and update ``availability``.
    ///
    /// - Parameter httpReachable: `model.state != .offline` from the
    ///   existing ``BuildStatusModel``, read at the call site so this model
    ///   stays independent of it.
    func refreshAvailability(httpReachable: Bool) async {
        let isPlistInstalled = FileManager.default.fileExists(atPath: DaemonControlCommands.plistPath.path)
        let isRegistered = await checkRegistration()
        availability = DaemonAvailabilityResolver.resolve(
            isPlistInstalled: isPlistInstalled,
            isRegistered: isRegistered,
            httpReachable: httpReachable
        )
    }

    /// Perform a daemon action, prompting for the repository folder first if
    /// none is configured yet. If the folder prompt is cancelled or the
    /// chosen folder fails validation, the action is silently abandoned (the
    /// picker itself already explained why, if validation failed).
    func perform(_ action: DaemonAction, httpReachable: Bool) async {
        guard let repoPath = resolveRepoPath() else { return }

        inFlightAction = action
        outputLog.removeAll()
        lastError = nil

        let command: SubprocessCommand
        switch action {
        case .install, .uninstall:
            command = DaemonControlCommands.command(for: action, repoPath: repoPath)
        case .start:
            command = DaemonControlCommands.startCommand()
        case .stop:
            command = DaemonControlCommands.stopCommand()
        }

        do {
            for try await line in await runner.run(command) {
                outputLog.append(line)
            }
        } catch {
            lastError = Self.describe(error)
        }

        inFlightAction = nil
        await refreshAvailability(httpReachable: httpReachable)
    }

    /// Clear the persisted repository path and immediately re-prompt.
    func relocate() {
        ControlTowerRepositoryConfiguration.clear()
        repoPath = RepositoryFolderPicker.presentAndPersist()
    }

    /// Check GitHub for a newer control-tower release than `localVersion`
    /// (the running daemon's self-reported version). Any fetch failure
    /// resolves to ``UpdateAvailability/unknown`` — never a blocking error.
    func checkForUpdates(localVersion: String?) async {
        let tag = try? await releaseClient.fetchLatestReleaseTag()
        updateAvailability = UpdateChecker.evaluate(localVersion: localVersion, remoteTag: tag)
    }

    /// Return the configured repo path, prompting for one if unset.
    private func resolveRepoPath() -> URL? {
        if let repoPath { return repoPath }
        let chosen = RepositoryFolderPicker.presentAndPersist()
        repoPath = chosen
        return chosen
    }

    /// Determine launchd registration by running the `launchctl print` check:
    /// a clean exit means registered, a non-zero exit means not registered,
    /// and a launch failure (e.g. `launchctl` itself missing) is `nil`.
    private func checkRegistration() async -> Bool? {
        do {
            for try await _ in await runner.run(DaemonControlCommands.registrationCheckCommand()) {}
            return true
        } catch SubprocessRunner.RunError.nonZeroExit {
            return false
        } catch {
            return nil
        }
    }

    private static func describe(_ error: Error) -> String {
        switch error {
        case SubprocessRunner.RunError.nonZeroExit(let status):
            "Exited with status \(status)."
        case SubprocessRunner.RunError.launchFailed(let reason):
            "Failed to launch: \(reason)"
        default:
            error.localizedDescription
        }
    }
}
