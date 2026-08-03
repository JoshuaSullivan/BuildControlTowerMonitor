import Foundation
import Testing
@testable import BuildControlTowerMonitor

/// Tests folder validation for the daemon control widget's repository picker.
struct RepositoryValidatorTests {
    private func makeTempDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func validWhenBuildScriptIsExecutable() throws {
        let dir = try makeTempDirectory()
        let script = dir.appending(path: "build.sh")
        FileManager.default.createFile(atPath: script.path, contents: Data("#!/bin/sh\n".utf8))
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        #expect(RepositoryValidator.validate(path: dir) == .valid)
    }

    @Test func missingBuildScript() throws {
        let dir = try makeTempDirectory()
        #expect(RepositoryValidator.validate(path: dir) == .missingBuildScript)
    }

    @Test func nonExecutableBuildScript() throws {
        let dir = try makeTempDirectory()
        let script = dir.appending(path: "build.sh")
        FileManager.default.createFile(atPath: script.path, contents: Data("#!/bin/sh\n".utf8))
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: script.path)
        #expect(RepositoryValidator.validate(path: dir) == .buildScriptNotExecutable)
    }

    @Test func notADirectory() throws {
        let dir = try makeTempDirectory()
        let file = dir.appending(path: "plainfile")
        FileManager.default.createFile(atPath: file.path, contents: Data())
        #expect(RepositoryValidator.validate(path: file) == .notADirectory)
    }
}
