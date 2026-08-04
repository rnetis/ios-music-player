import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var player: PlayerManager
    @StateObject private var library = LibraryModel()
    @State private var searchText = ""
    @State private var showRepos = false
    @State private var showPlayer = false

    private var filteredTracks: [Track] {
        let all = library.tracks
        guard !searchText.isEmpty else { return all }
        return all.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Library")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showRepos = true
                        } label: {
                            Label("Repos", systemImage: "externaldrive.badge.plus")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if library.isRefreshing {
                            ProgressView()
                        } else {
                            Button {
                                Task { await library.refresh() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    }
                }
                .searchable(text: $searchText)
                .sheet(isPresented: $showRepos) {
                    ReposView().environmentObject(library)
                }
                .sheet(isPresented: $showPlayer) {
                    PlayerView().environmentObject(player)
                }
                .safeAreaInset(edge: .bottom) {
                    MiniPlayerView(showPlayer: $showPlayer)
                        .environmentObject(player)
                }
        }
        .task { await library.load() }
    }

    @ViewBuilder
    private var content: some View {
        if library.tracks.isEmpty {
            emptyState
        } else {
            List {
                ForEach(Array(filteredTracks.enumerated()), id: \.element.id) { index, track in
                    Button {
                        player.play(tracks: filteredTracks, startAt: index)
                    } label: {
                        TrackRow(track: track)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("No music yet")
                .font(.title2.bold())
            Text("Add a hosted JSON repo to load your music.")
                .foregroundColor(.secondary)
            Button("Add Music Repo") { showRepos = true }
                .buttonStyle(.borderedProminent)
            if let error = library.statuses.first(where: { $0.error != nil })?.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
