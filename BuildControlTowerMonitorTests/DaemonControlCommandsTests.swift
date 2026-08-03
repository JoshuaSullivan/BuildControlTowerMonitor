import Foundation
import Testing
@testable import BuildControlTowerMonitor

/// Tests the exact subprocess commands built for each daemon action.
struct DaemonControlCommandsTests {
    private let repoPath = URL(fileURLWithPath: "/Users/josh/build-control-tower")

    @Test func installCommand() {
        let command = DaemonControlCommands.command(for: .install(skipTests: false), repoPath: repoPath)
        #expect(command.executableURL == repoPath.appending(path: "build.sh"))
        #expect(command.arguments == ["--install-agent"])
        #expect(command.currentDirectoryURL == repoPath)
    }

    @Test func installCommandWithSkipTests() {
        let command = DaemonControlCommands.command(for: .install(skipTests: true), repoPath: repoPath)
        #expect(command.arguments == ["--install-agent", "--skip-tests"])
    }

    @Test func uninstallCommand() {
        let command = DaemonControlCommands.command(for: .uninstall, repoPath: repoPath)
        #expect(command.executableURL == repoPath.appending(path: "build.sh"))
        #expect(command.arguments == ["--uninstall-agent"])
        #expect(command.currentDirectoryURL == repoPath)
    }

    @Test func startCommand() {
        let command = DaemonControlCommands.startCommand(uid: 501)
        #expect(command.executableURL == URL(fileURLWithPath: "/bin/launchctl"))
        #expect(command.arguments == ["bootstrap", "gui/501", DaemonControlCommands.plistPath.path])
        #expect(command.currentDirectoryURL == nil)
    }

    @Test func stopCommand() {
        let command = DaemonControlCommands.stopCommand(uid: 501)
        #expect(command.executableURL == URL(fileURLWithPath: "/bin/launchctl"))
        #expect(command.arguments == ["bootout", "gui/501/com.build-control-tower.daemon"])
    }

    @Test func registrationCheckCommand() {
        let command = DaemonControlCommands.registrationCheckCommand(uid: 501)
        #expect(command.executableURL == URL(fileURLWithPath: "/bin/launchctl"))
        #expect(command.arguments == ["print", "gui/501/com.build-control-tower.daemon"])
    }
}
