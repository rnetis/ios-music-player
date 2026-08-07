import Foundation

/// Per-repo fetch result, shown in the repos screen.
struct RepoStatus: Identifiable {
    let id = UUID()
    let url: URL
    let name: String?
    let tracks: [Track]
    let error: String?

    var trackCount: Int { tracks.count }
}

enum RepoError: LocalizedError {
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Please enter a valid http(s) URL."
        }
    }
}

/// A repo may be a bare array of tracks or an object with a "tracks" array.
struct RepoPayload: Decodable {
    let name: String?
    let tracks: [Track]?
}

/// Persists the list of hosted JSON repos and fetches/parses them.
/// Multiple repos are supported; tracks are merged and deduplicated by URL.
final class RepoService {

    static let shared = RepoService()

    /// Sample repo bundled with this project — hosted at the repo's own raw URL.
    static let sampleRepoURL = URL(
        string: "https://raw.githubusercontent.com/rnetis/ios-music-player/main/sample-repo.json"
    )!

    private let defaults = UserDefaults.standard
    private let repoURLsKey = "musicRepoURLs"

    var repoURLs: [URL] {
        (defaults.stringArray(forKey: repoURLsKey) ?? []).compactMap { URL(string: $0) }
    }

    // MARK: - Repo list management

    func addRepo(_ urlString: String) throws {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            throw RepoError.invalidURL
        }
        var current = repoURLs
        guard !current.contains(where: { $0.absoluteString == url.absoluteString }) else { return }
        current.append(url)
        defaults.set(current.map(\.absoluteString), forKey: repoURLsKey)
    }

    func removeRepo(_ url: URL) {
        var current = repoURLs
        current.removeAll { $0.absoluteString == url.absoluteString }
        defaults.set(current.map(\.absoluteString), forKey: repoURLsKey)
    }

    func removeRepos(at offsets: IndexSet) {
        var current = repoURLs
        for index in offsets.sorted(by: >) where current.indices.contains(index) {
            current.remove(at: index)
        }
        defaults.set(current.map(\.absoluteString), forKey: repoURLsKey)
    }

    // MARK: - Fetching

    func fetchAll(urls: [URL]) async -> [RepoStatus] {
        await withTaskGroup(of: RepoStatus.self) { group in
            for url in urls {
                group.addTask { await self.fetch(url: url) }
            }
            var results: [RepoStatus] = []
            for await status in group {
                results.append(status)
            }
            return results.sorted { a, b in
                (urls.firstIndex(of: a.url) ?? .max) < (urls.firstIndex(of: b.url) ?? .max)
            }
        }
    }

    func fetch(url: URL) async -> RepoStatus {
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                return RepoStatus(url: url, name: nil, tracks: [], error: "HTTP \(http.statusCode)")
            }
            let (name, tracks) = try parse(data: data)
            return RepoStatus(url: url, name: name, tracks: tracks, error: nil)
        } catch {
            return RepoStatus(url: url, name: nil, tracks: [], error: error.localizedDescription)
        }
    }

    private func parse(data: Data) throws -> (String?, [Track]) {
        let decoder = JSONDecoder()
        if let tracks = try? decoder.decode([Track].self, from: data) {
            return (nil, tracks)
        }
        let payload = try decoder.decode(RepoPayload.self, from: data)
        return (payload.name, payload.tracks ?? [])
    }
}
