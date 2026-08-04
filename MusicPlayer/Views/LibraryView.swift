import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var player: PlayerManager
    @StateObject private var library = LibraryModel()
    @State private var searchText = ""
    @State private var showRepos = false
    @State private var showPlayer = false
    @State private var selectedSortOption: SortOption = .title
    @State private var isAscending = true
    
    enum SortOption: String, CaseIterable {
        case title = "Title"
        case artist = "Artist"
        case dateAdded = "Date Added"
    }
    
    private var filteredTracks: [Track] {
        let all = library.tracks
        guard !searchText.isEmpty else { 
            return sortedTracks(all)
        }
        let filtered = all.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.artist.localizedCaseInsensitiveContains(searchText)
        }
        return sortedTracks(filtered)
    }
    
    private func sortedTracks(_ tracks: [Track]) -> [Track] {
        tracks.sorted { track1, track2 in
            switch selectedSortOption {
            case .title:
                return isAscending ? track1.title < track2.title : track1.title > track2.title
            case .artist:
                return isAscending ? track1.artist < track2.artist : track1.artist > track2.artist
            case .dateAdded:
                return isAscending ? track1.id < track2.id : track1.id > track2.id
            }
        }
    }

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Library")
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showRepos = true
                        } label: {
                            Label("Repos", systemImage: "externaldrive.badge.plus")
                                .foregroundColor(.purple)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            // Sort menu
                            Menu {
                                Picker("Sort by", selection: $selectedSortOption) {
                                    ForEach(SortOption.allCases, id: \.self) { option in
                                        Label(option.rawValue, systemImage: option == selectedSortOption ? "checkmark" : "none")
                                    }
                                }
                                
                                Divider()
                                
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isAscending.toggle()
                                    }
                                } label: {
                                    Label(isAscending ? "Ascending" : "Descending", 
                                          systemImage: isAscending ? "arrow.up" : "arrow.down")
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down.circle")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                            }
                            
                            // Refresh button
                            if library.isRefreshing {
                                ProgressView()
                            } else {
                                Button {
                                    Task { await library.refresh() }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.purple)
                                }
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
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.98, green: 0.97, blue: 0.99), Color(red: 0.95, green: 0.94, blue: 0.97)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Track count badge
            if !filteredTracks.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(filteredTracks.count) track\(filteredTracks.count != 1 ? "s" : "")")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 80)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                Image(systemName: "music.note.list")
                    .font(.system(size: 60, weight: .ultraLight))
                    .foregroundColor(.purple.opacity(0.6))
            }
            Text("No music yet")
                .font(.title2.bold())
                .foregroundColor(.primary)
            Text("Add a hosted JSON repo to load your music.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Add Music Repo") { showRepos = true }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            if let error = library.statuses.first(where: { $0.error != nil })?.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.97, blue: 0.99), Color(red: 0.95, green: 0.94, blue: 0.97)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
