import Foundation

/// Launches subprocesses and streams their output.
///
/// An `actor` because `Process` is not `Sendable`; every launch is isolated
/// here rather than touching `Process`/`Pipe` from arbitrary call sites. This
/// is the only file in the app that imports `Process` directly — command
/// construction (``DaemonControlCommands``) and the resulting state
/// (``DaemonControlModel``) stay plain Foundation/SwiftUI and independently
/// testable.
actor SubprocessRunner {
    /// A single line of output from a running subprocess.
    struct OutputLine: Sendable, Equatable {
        /// The line's text, without its trailing newline.
        let text: String
        /// Which stream the line came from.
        let stream: Stream
    }

    /// Which stream a line of output came from.
    nonisolated enum Stream: Sendable, Equatable {
        case standardOutput
        case standardError
    }

    /// A subprocess launch or exit failure.
    nonisolated enum RunError: Error, Sendable, Equatable {
        /// The process exited with a non-zero status.
        case nonZeroExit(Int32)
        /// The process could not be launched at all.
        case launchFailed(String)
    }

    /// Launch `command` and stream its combined stdout/stderr line-by-line.
    ///
    /// The returned stream finishes normally when the process exits `0`, and
    /// throws ``RunError/nonZeroExit(_:)`` or ``RunError/launchFailed(_:)``
    /// otherwise. There is no completion-handler surface to dangle: the
    /// process's `terminationHandler` resolves a checked continuation that
    /// finishes the stream from inside a `Task`.
    func run(_ command: SubprocessCommand) -> AsyncThrowingStream<OutputLine, Error> {
        AsyncThrowingStream { continuation in
            let process = Process()
            process.executableURL = command.executableURL
            process.arguments = command.arguments
            process.currentDirectoryURL = command.currentDirectoryURL

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            Self.forwardLines(from: stdoutPipe, stream: .standardOutput, into: continuation)
            Self.forwardLines(from: stderrPipe, stream: .standardError, into: continuation)

            process.terminationHandler = { finished in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                if finished.terminationStatus == 0 {
                    continuation.finish()
                } else {
                    continuation.finish(throwing: RunError.nonZeroExit(finished.terminationStatus))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.finish(throwing: RunError.launchFailed(error.localizedDescription))
            }
        }
    }

    /// Feed each newline-delimited chunk read from `pipe` into `continuation`
    /// as an ``OutputLine``, tagged with `stream`.
    private static func forwardLines(
        from pipe: Pipe,
        stream: Stream,
        into continuation: AsyncThrowingStream<OutputLine, Error>.Continuation
    ) {
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
                continuation.yield(OutputLine(text: String(line), stream: stream))
            }
        }
    }
}
