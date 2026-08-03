import Foundation

/// A subprocess to launch: what to run, with what arguments, from where.
///
/// Kept separate from ``SubprocessRunner`` so command construction (which
/// executable, which flags, which working directory) is a pure value that can
/// be unit-tested without ever actually launching a process.
nonisolated struct SubprocessCommand: Sendable, Equatable {
    /// The executable to launch.
    let executableURL: URL

    /// Arguments passed to the executable.
    let arguments: [String]

    /// The working directory the process launches in, if any.
    let currentDirectoryURL: URL?
}
