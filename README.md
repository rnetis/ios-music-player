# Music Player (iOS)

A sideloadable iOS music player that plays **every audio format** — Opus, FLAC, MP3, M4A/AAC, OGG, WAV, ALAC, WMA, AC3, DTS, … — from **multiple hosted JSON repos**: any JSON file hosted anywhere on the internet (GitHub raw, gist, any CDN) that lists tracks with their URL, title and artist.

- 🎵 Universal playback: **hybrid engine** — AVFoundation handles the formats it decodes natively (mp3/m4a/aac/alac/flac/wav/aiff/caf/mp4, hardware-accelerated), **VLCKit** covers everything else (opus/ogg/wma/ac3/dts/…) — so every format plays and the common ones are bulletproof
- 📚 Add **unlimited JSON repos** in-app; tracks are merged and deduplicated by URL
- 🎧 Lock-screen controls, background audio, artwork, shuffle/repeat, seek, volume, search
- 📦 A GitHub Action builds an **unsigned IPA** on every `v*` tag and attaches it to a Release — ready for AltStore / Sideloadly / ESign

---

## Repo JSON format

Point the app at any JSON file. Two shapes are accepted:

**Bare array:**

```json
[
  {
    "url": "https://example.com/music/song1.opus",
    "title": "Song One",
    "artist": "Some Artist"
  }
]
```

**Object with a `tracks` array** (recommended — lets you name the repo):

```json
{
  "name": "My Radio",
  "description": "Optional",
  "tracks": [
    {
      "url": "https://example.com/music/song1.flac",
      "title": "Song One",
      "artist": "Some Artist",
      "album": "Album Name (optional)",
      "artwork": "https://example.com/covers/song1.jpg (optional)",
      "duration": 240
    }
  ]
}
```

Field notes:

| field      | required | notes |
|------------|----------|-------|
| `url`      | ✅       | Direct link to the audio file or stream (http/https). |
| `title`    | ✅       | `name` is accepted as an alias. Falls back to the file name. |
| `artist`   | ✅       | Falls back to "Unknown Artist". |
| `album`    | –        | Optional, shown on the player screen. |
| `artwork`  | –        | Optional cover art URL (`cover` accepted as an alias). |
| `duration` | –        | Optional hint in seconds (the app reads the real duration from the file anyway). |

`sample-repo.json` and `sample-repo-2.json` in this repo are working examples (one track per format) — you can host them anywhere and add them in-app.

## Adding repos in the app

1. Open the app → tap the **repos** icon (top-left) or "Add Music Repo".
2. Paste the URL of any hosted JSON (e.g. `https://raw.githubusercontent.com/<you>/<repo>/main/music.json`).
3. Tap **Add**. Repeat for as many repos as you like. Swipe left on a repo to remove it.

## Building locally (macOS + Xcode)

```bash
brew install xcodegen
xcodegen generate          # creates MusicPlayer.xcodeproj
open MusicPlayer.xcodeproj
```

Select your signing team under **Signing & Capabilities**, then Run on a device or simulator. (The GitHub Action builds it unsigned for sideloading, so no paid account needed there.)

## Building the unsigned IPA with GitHub Actions

1. Push this repo to GitHub.
2. The in-app "Add sample repo" button already points at this repo's `sample-repo.json`. For your **own** repos, host the JSON anywhere and paste the URL in the app.
3. Tag and push:

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

4. The **Build Unsigned IPA** workflow runs on the macOS runner: generates the project, builds with `CODE_SIGNING_ALLOWED=NO`, packages `Payload/MusicPlayer.app` into `MusicPlayer-unsigned.ipa`, and creates a GitHub Release with the IPA attached.

Manual builds: use **Actions → Build Unsigned IPA → Run workflow** (uploads the IPA as an artifact instead of a Release).

## Sideloading the IPA

The IPA is unsigned, so it must be re-signed on install:

- **AltStore** (free, 7-day refresh) — open the Release, download the IPA, "Open in AltStore".
- **Sideloadly** (Windows/macOS, free Apple ID) — drag the IPA, enter your Apple ID, install.
- **ESign / TrollStore** — import and sign with any certificate.

## Format support

| Format           | AVFoundation (fallback) | VLCKit (primary) |
|------------------|:-----------------------:|:----------------:|
| MP3              | ✅                      | ✅               |
| M4A / AAC        | ✅                      | ✅               |
| ALAC             | ✅                      | ✅               |
| FLAC             | ✅ (iOS 11+)            | ✅               |
| WAV / AIFF / CAF | ✅                      | ✅               |
| **Opus**         | ❌                      | ✅               |
| OGG / Vorbis     | ❌                      | ✅               |
| WebM / Matroska  | ❌                      | ✅               |
| WMA / APE / AC3 / DTS / … | ❌           | ✅               |

The app picks VLCKit when present and silently falls back to AVFoundation otherwise, so the build succeeds with or without the package.

## Project structure

```
project.yml                        # XcodeGen spec (single source of truth)
MusicPlayer/
  MusicPlayerApp.swift             # app entry
  Info.plist                       # background audio, ATS, orientations
  Models/Track.swift               # track model + JSON decoding
  Services/RepoService.swift       # repo list persistence + fetching/parsing
  Services/LibraryModel.swift      # merges & dedupes tracks across repos
  Services/PlayerManager.swift     # queue, engine, lock screen, remote commands
  Engines/AudioEngine.swift        # engine protocol + factory
  Engines/VLCEngine.swift          # VLCKit engine (universal formats)
  Engines/AVFoundationEngine.swift # AVPlayer fallback engine
  Views/…                          # Library, Player, Mini player, Repos, rows
  Assets.xcassets/AppIcon.appiconset/
sample-repo.json, sample-repo-2.json
scripts/make_icon.py               # regenerates AppIcon.png (stdlib only)
.github/workflows/build-ipa.yml    # unsigned IPA build + release
```

## Notes

- **Bundle ID** defaults to `com.example.musicplayer` — change it in `project.yml` if you plan to keep a stable identity across installs.
- **ATS**: `NSAllowsArbitraryLoads` is enabled because repos/music are often served over plain http. Tighten it in `Info.plist` if you only use https. `NSLocalNetworkUsageDescription` is set so LAN servers (e.g. `http://192.168.x.x/music.json`) trigger the proper iOS local-network permission prompt.
- **VLCKit** is a large binary (~150 MB); the first build fetches it from `code.videolan.org` and takes a few minutes. It's pinned via SPM to the default branch `master` (VLCKit 4.0-dev, checksum-pinned binary) — no released 3.x tag ships a root `Package.swift`.
- Deployment target is iOS 15.0+.

## License

MIT — see [LICENSE](LICENSE).
