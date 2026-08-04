import Combine
import Foundation

/// Loads and merges tracks from all configured JSON repos.
final class LibraryModel: ObservableObject {

    @Published private(set) var tracks: [Track] = []
    @Published private(set) var statuses: [RepoStatus] = []
    @Published private(set) var isRefreshing = false

    private let service = RepoService.shared

    var repoURLs: [URL] { service.repoURLs }

    func load() async {
        guard tracks.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let urls = service.repoURLs
        guard !urls.isEmpty else {
            statuses = []
            tracks = []
            return
        }

        let results = await service.fetchAll(urls: urls)
        statuses = results

        // Merge all repos, deduplicating by track URL (first one wins).
        var seen = Set<String>()
        var merged: [Track] = []
        for status in results {
            for track in status.tracks where seen.insert(track.url.absoluteString).inserted {
                merged.append(track)
            }
        }
        tracks = merged
    }

    func addRepo(_ urlString: String) throws {
        try service.addRepo(urlString)
        Task { await refresh() }
    }

    func addSampleRepo() {
        try? service.addRepo(RepoService.sampleRepoURL.absoluteString)
        Task { await refresh() }
    }

    func removeRepos(at offsets: IndexSet) {
        service.removeRepos(at: offsets)
        Task { await refresh() }
    }
}
