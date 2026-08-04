import Foundation

/// A single playable track parsed from a hosted JSON repo.
///
/// JSON schema (each track):
///   { "url": "https://.../song.flac", "title": "Song Name",
///     "artist": "Artist", "album": "Album (optional)",
///     "artwork": "https://.../cover.jpg (optional)",
///     "duration": 240 (optional, seconds) }
/// `name` is accepted as an alias for `title`, `cover` for `artwork`.
struct Track: Identifiable, Decodable, Hashable {
    let id = UUID()
    var url: URL
    var title: String
    var artist: String
    var album: String?
    var artworkURL: URL?
    var duration: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case url, title, name, artist, album, artwork, cover, duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)

        let titleValue = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .name)
        title = titleValue ?? url.deletingPathExtension().lastPathComponent

        artist = try container.decodeIfPresent(String.self, forKey: .artist) ?? "Unknown Artist"
        album = try container.decodeIfPresent(String.self, forKey: .album)

        let artworkValue = try container.decodeIfPresent(String.self, forKey: .artwork)
            ?? container.decodeIfPresent(String.self, forKey: .cover)
        artworkURL = artworkValue.flatMap(URL.init(string:))

        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
    }
}
