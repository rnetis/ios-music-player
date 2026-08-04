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
                        TextField("https://example.com/music.json", text: $newRepoURL)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Add") { addRepo() }
                            .disabled(newRepoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Add a hosted JSON repo")
                } footer: {
                    Text("Point to any JSON file hosted anywhere (GitHub raw, gist, CDN…). It can be a bare array of tracks or an object with a \"tracks\" array. Add as many repos as you like.")
                }

                Section("Repos (\(library.repoURLs.count))") {
                    if library.repoURLs.isEmpty {
                        Text("No repos yet. Add one above, or tap the sample button below.")
                            .foregroundColor(.secondary)
                    }
                    ForEach(library.statuses) { status in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(status.name ?? status.url.host ?? status.url.absoluteString)
                                    .font(.body)
                                Text(status.url.absoluteString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if let error = status.error {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                            } else {
                                Text("\(status.trackCount)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        library.removeRepos(at: offsets)
                    }
                }

                Section {
                    Button {
                        library.addSampleRepo()
                    } label: {
                        Label("Add sample repo", systemImage: "plus.circle")
                    }
                    Button {
                        Task { await library.refresh() }
                    } label: {
                        Label("Refresh all", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Music Repos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
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
