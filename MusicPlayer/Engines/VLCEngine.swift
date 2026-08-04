#if canImport(VLCKit)
import Foundation
import VLCKit

/// Playback engine backed by VLCKit. Handles virtually every audio format:
/// opus, ogg/vorbis, flac, mp3, m4a/aac, alac, wav, aiff, wma, ape,
/// ac3, dts, webm and more — both files and live streams.
final class VLCEngine: AudioEngine {

    private let player = VLCMediaPlayer()
    private var endedObserver: NSObjectProtocol?

    var onEndReached: (() -> Void)?

    init() {
        endedObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("VLCMediaPlayerEndReached"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onEndReached?()
        }
    }

    deinit {
        if let endedObserver = endedObserver {
            NotificationCenter.default.removeObserver(endedObserver)
        }
        player.stop()
    }

    var isPlaying: Bool {
        player.isPlaying
    }

    var currentTime: TimeInterval {
        Double(player.time.intValue) / 1000.0
    }

    var duration: TimeInterval {
        let milliseconds = player.length.intValue
        return milliseconds > 0 ? Double(milliseconds) / 1000.0 : 0
    }

    var volume: Float {
        get { Float(player.audio.volume) / 100.0 }
        set { player.audio.volume = Int32(newValue * 100) }
    }

    func load(url: URL) {
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
