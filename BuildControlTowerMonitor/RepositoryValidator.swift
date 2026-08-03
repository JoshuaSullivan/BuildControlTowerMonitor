import Foundation

/// The result of checking whether a chosen folder looks like the
/// `build-control-tower` repository.
nonisolated enum RepositoryValidationResult: Equatable, Sendable {
    /// The folder contains an executable `build.sh`.
    case valid
    /// The chosen path is not a directory.
    case notADirectory
    /// No `build.sh` was found at the folder's root.
    case missingBuildScript
    /// `build.sh` exists but isn't executable.
    case buildScriptNotExecutable

    /// A human-readable explanation, shown in the folder-picker's error alert.
    var reason: String {
        switch self {
        case .valid:
            "The folder is valid."
        case .notADirectory:
            "That isn't a folder. Choose the root of the build-control-tower repository."
        case .missingBuildScript:
            "This folder doesn't contain a build.sh — pick the root of the build-control-tower repository."
        case .buildScriptNotExecutable:
            "build.sh isn't executable — run chmod +x build.sh in that repo, or re-clone it."
        }
    }
}

/// Validates that a folder chosen via the repository picker is a usable
/// `build-control-tower` checkout: it must contain an executable `build.sh`,
/// since every daemon action shells out to it.
nonisolated enum RepositoryValidator {
    /// Validate a candidate repository folder.
    static func validate(path: URL, fileManager: FileManager = .default) -> RepositoryValidationResult {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return .notADirectory
        }
        let buildScript = path.appending(path: "build.sh")
        guard fileManager.fileExists(atPath: buildScript.path) else {
            return .missingBuildScript
        }
        guard fileManager.isExecutableFile(atPath: buildScript.path) else {
            return .buildScriptNotExecutable
        }
        return .valid
    }
}
