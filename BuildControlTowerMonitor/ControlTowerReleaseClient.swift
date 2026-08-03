import Foundation

/// Fetches the latest published release tag of the `build-control-tower`
/// repository from the public GitHub API, for the daemon control widget's
/// update check.
///
/// Unauthenticated: the repository is public and this is called at most once
/// per widget-open, well under GitHub's 60 requests/hour unauthenticated
/// limit even shared across a team on one office IP.
nonisolated struct ControlTowerReleaseClient: Sendable {
    /// Errors surfaced by ``fetchLatestReleaseTag()``.
    enum ReleaseCheckError: Error, Sendable {
        case badStatus(Int)
        case decodingFailed
    }

    /// The `/releases/latest` endpoint for the control-tower repository.
    private static let endpoint = URL(
        string: "https://api.github.com/repos/JoshuaSullivan/build-control-tower/releases/latest"
    )!

    /// The session used for requests.
    let session: URLSession

    /// Create a client. When `session` is omitted, a non-caching ephemeral
    /// session is built; pass a custom session (e.g. backed by a `URLProtocol`
    /// stub) in tests.
    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.urlCache = nil
            self.session = URLSession(configuration: configuration)
        }
    }

    /// The subset of GitHub's release payload this client needs.
    private struct ReleasePayload: Decodable {
        let tagName: String
        enum CodingKeys: String, CodingKey { case tagName = "tag_name" }
    }

    /// Fetch the latest release's tag name, e.g. `"v0.2.0"`.
    func fetchLatestReleaseTag() async throws -> String {
        var request = URLRequest(url: Self.endpoint)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ReleaseCheckError.badStatus(code)
        }
        guard let payload = try? JSONDecoder().decode(ReleasePayload.self, from: data) else {
            throw ReleaseCheckError.decodingFailed
        }
        return payload.tagName
    }
}
