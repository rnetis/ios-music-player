#if canImport(VLCKit)
import Foundation
import VLCKit

/// Playback engine backed by VLCKit. Handles virtually every audio format:
/// opus, ogg/vorbis, flac, mp3, m4a/aac, alac, wav, aiff, wma, ape,
/// ac3, dts, webm and more — both files and live streams.
///
/// VLCKit 4.0 (SPM `master` branch) API notes:
///  - `length` moved to `VLCMedia` -> `player.media?.length`
///  - `player.audio` is now nullable (weak)
///  - the `EndReached` notification no longer exists; natural end of a
///    track surfaces as a state change to `.stopped` (the same signal
///    `VLCMediaListPlayer` uses to advance its queue).
final class VLCEngine: AudioEngine {

    private let player = VLCMediaPlayer()
    private var endedObserver: NSObjectProtocol?
    private var lastState: VLCMediaPlayerState = .stopped
    private var loadingNewMedia = false

    var onEndReached: (() -> Void)?

    init() {
        endedObserver = NotificationCenter.default.addObserver(
            forName: VLCMediaPlayer.stateChangedNotification,
            object: player,
            queue: .main
        ) { [weak self] _ in
            self?.handleStateChange()
        }
    }

    deinit {
        if let endedObserver = endedObserver {
            NotificationCenter.default.removeObserver(endedObserver)
        }
        player.stop()
    }

    /// Natural end = `.playing` -> `.stopped`. Transitions caused by loading
    /// a new media are swallowed via `loadingNewMedia`.
    private func handleStateChange() {
        let newState = player.state
        defer { lastState = newState }
        if loadingNewMedia {
            if newState == .opening || newState == .playing {
                loadingNewMedia = false
            }
            return
        }
        if lastState == .playing && newState == .stopped {
            onEndReached?()
        }
    }

    var isPlaying: Bool {
        player.isPlaying
    }

    var currentTime: TimeInterval {
        Double(player.time.intValue) / 1000.0
    }

    var duration: TimeInterval {
        let milliseconds = player.media?.length.intValue ?? 0
        return milliseconds > 0 ? Double(milliseconds) / 1000.0 : 0
    }

    var volume: Float {
        get { Float(player.audio?.volume ?? 0) / 100.0 }
        set { player.audio?.volume = Int32(newValue * 100) }
    }

    func load(url: URL) {
        loadingNewMedia = true
        player.media = VLCMedia(url: url)
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.stop()
    }

    func seek(to time: TimeInterval) {
        player.time = VLCTime(int: Int32(max(0, time) * 1000))
    }
}
#endif
