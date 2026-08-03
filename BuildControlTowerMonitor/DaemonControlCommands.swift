import Foundation

/// A daemon lifecycle action the control widget can perform.
nonisolated enum DaemonAction: Sendable, Equatable {
    /// Build from source and register the launchd agent (`build.sh --install-agent`).
    case install(skipTests: Bool)
    /// Stop the daemon and remove the launchd agent (`build.sh --uninstall-agent`).
    case uninstall
    /// Re-register the still-installed agent from its plist (`launchctl bootstrap`).
    ///
    /// `launchctl bootout` (used by ``DaemonAction/stop``) fully de-registers
    /// the job, not merely pauses it — a plain `kickstart` on a de-registered
    /// job fails outright. `bootstrap` re-registers it, and its `RunAtLoad`
    /// key (baked into the plist by `build.sh`) starts it immediately.
    case start
    /// Stop a running agent, fully de-registering it until the next Start or
    /// Install (`launchctl bootout`).
    case stop
}

/// Builds the exact ``SubprocessCommand`` for each daemon action, and for the
/// `launchctl` registration check that determines whether the agent is
/// installed. Kept pure and separate from ``SubprocessRunner`` so the exact
/// executable/arguments/working directory are independently testable without
/// launching anything.
nonisolated enum DaemonControlCommands {
    /// The daemon's launchd label, as registered by `build.sh`.
    static let launchAgentLabel = "com.build-control-tower.daemon"

    /// Where `build.sh --install-agent` writes the daemon's LaunchAgent
    /// plist, and `--uninstall-agent` removes it. Its presence is the
    /// "installed" signal — `bootout` (used by ``DaemonAction/stop``) fully
    /// de-registers the launchd job, so registration alone can't tell
    /// "stopped" from "never installed".
    static let plistPath = URL(fileURLWithPath: NSHomeDirectory())
        .appending(path: "Library/LaunchAgents/\(launchAgentLabel).plist")

    /// The command for a repo-relative daemon action (install/uninstall).
    static func command(for action: DaemonAction, repoPath: URL) -> SubprocessCommand {
        let buildScript = repoPath.appending(path: "build.sh")
        switch action {
        case .install(let skipTests):
            var arguments = ["--install-agent"]
            if skipTests { arguments.append("--skip-tests") }
            return SubprocessCommand(executableURL: buildScript, arguments: arguments, currentDirectoryURL: repoPath)
        case .uninstall:
            return SubprocessCommand(
                executableURL: buildScript,
                arguments: ["--uninstall-agent"],
                currentDirectoryURL: repoPath
            )
        case .start, .stop:
            preconditionFailure("start/stop are launchctl commands; use startCommand()/stopCommand() instead")
        }
    }

    /// `launchctl bootstrap gui/<uid> <plistPath>`
    ///
    /// Re-registers the agent from its already-installed plist; `RunAtLoad`
    /// brings it up immediately. This is the counterpart to `stop`'s
    /// `bootout`, not a resend of `install` — it touches no source and
    /// installs no new binary.
    static func startCommand(uid: uid_t = getuid()) -> SubprocessCommand {
        SubprocessCommand(
            executableURL: launchctlURL,
            arguments: ["bootstrap", "gui/\(uid)", plistPath.path],
            currentDirectoryURL: nil
        )
    }

    /// `launchctl bootout gui/<uid>/com.build-control-tower.daemon`
    static func stopCommand(uid: uid_t = getuid()) -> SubprocessCommand {
        SubprocessCommand(
            executableURL: launchctlURL,
            arguments: ["bootout", domain(uid: uid)],
            currentDirectoryURL: nil
        )
    }

    /// `launchctl print gui/<uid>/com.build-control-tower.daemon`
    ///
    /// Exit code `0` means the agent is registered with launchd; a non-zero
    /// exit means it isn't. The command's output is not otherwise parsed.
    static func registrationCheckCommand(uid: uid_t = getuid()) -> SubprocessCommand {
        SubprocessCommand(
            executableURL: launchctlURL,
            arguments: ["print", domain(uid: uid)],
            currentDirectoryURL: nil
        )
    }

    private static let launchctlURL = URL(fileURLWithPath: "/bin/launchctl")

    private static func domain(uid: uid_t) -> String {
        "gui/\(uid)/\(launchAgentLabel)"
    }
}
