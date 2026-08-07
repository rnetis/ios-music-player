import SwiftUI

struct ReposView: View {
    @EnvironmentObject var library: LibraryModel
    @Environment(\.dismiss) private var dismiss
    @State private var newRepoURL = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        TextField("http(s)://example.com/music.json", text: $newRepoURL)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Add") { addRepo() }
                            .disabled(newRepoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .font(.body.weight(.semibold))
                    }
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Add a hosted JSON repo")
                        .foregroundColor(.purple.opacity(0.8))
                } footer: {
                    Text("Point to any JSON file hosted anywhere (GitHub raw, gist, CDN…). It can be a bare array of tracks or an object with a \"tracks\" array. Add as many repos as you like.")
                        .font(.caption2)
                }
                .listRowBackground(Color.white.opacity(0.05))

                Section("Repos (\(library.repoURLs.count))") {
                    if library.repoURLs.isEmpty {
                        Text("No repos yet. Add one above, or tap the sample button below.")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    ForEach(library.statuses) { status in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(status.name ?? status.url.host ?? status.url.absoluteString)
                                    .font(.body.weight(.medium))
                                Text(status.url.absoluteString)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(1)
                            }
                            Spacer()
                            if status.error != nil {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            } else {
                                Text("\(status.trackCount)")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.purple.opacity(0.15))
                                    )
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    .onDelete { offsets in
                        library.removeRepos(at: offsets)
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))

                Section {
                    Button {
                        library.addSampleRepo()
                    } label: {
                        Label("Add sample repo", systemImage: "plus.circle.fill")
                    }
                    .tint(.purple)
                    
                    Button {
                        Task { await library.refresh() }
                    } label: {
                        Label("Refresh all", systemImage: "arrow.clockwise")
                    }
                    .tint(.blue)
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .navigationTitle("Music Repos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundCompat()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.body.weight(.semibold))
                }
            }
            .hiddenScrollContentBackground()
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.10, blue: 0.30),
                        Color(red: 0.05, green: 0.02, blue: 0.10),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .task { await library.load() }
    }

    private func addRepo() {
        let trimmed = newRepoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try library.addRepo(trimmed)
            newRepoURL = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
