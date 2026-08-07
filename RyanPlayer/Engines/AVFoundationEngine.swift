import AVFoundation
import Foundation

/// Playback engine backed by AVPlayer. Natively covers mp3, m4a/aac,
/// alac, flac, wav, aiff, caf and mp4.
final class AVFoundationEngine: AudioEngine {

    private var player: AVPlayer?
    private var endedObserver: NSObjectProtocol?

    var onEndReached: (() -> Void)?

    var isPlaying: Bool {
        player?.timeControlStatus == .playing
    }

    var currentTime: TimeInterval {
        guard let time = player?.currentTime(), time.isNumeric else { return 0 }
        return CMTimeGetSeconds(time)
    }

    var duration: TimeInterval {
        guard let item = player?.currentItem,
              let duration = item.duration.isNumeric ? item.duration : nil else { return 0 }
        let seconds = CMTimeGetSeconds(duration)
        return seconds.isFinite && seconds > 0 ? seconds : 0
    }

    var volume: Float {
        get { player?.volume ?? 1 }
        set { player?.volume = newValue }
    }

    func load(url: URL) {
        if let endedObserver = endedObserver {
            NotificationCenter.default.removeObserver(endedObserver)
            self.endedObserver = nil
        }
        let item = AVPlayerItem(url: url)
        if player == nil {
            player = AVPlayer()
        }
        player?.replaceCurrentItem(with: item)
        endedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.onEndReached?()
        }
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func stop() {
        player?.pause()
        player = nil
    }

    func seek(to time: TimeInterval) {
        player?.seek(
            to: CMTime(seconds: max(0, time), preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }
}
