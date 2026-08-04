import Foundation

/// Routes each track to the best available engine:
/// - `AVFoundationEngine` for formats AVPlayer decodes natively (mp3, m4a/aac,
///   alac, flac, wav, aiff, caf, mp4) — hardware-accelerated and rock solid.
/// - `VLCEngine` (VLCKit 4.0-dev) for everything else (opus, ogg, wma, ac3,
///   dts, ape, webm …).
///
/// Why: VLCKit's dev branch regresses on plain AAC-in-M4A over http, while
/// AVFoundation plays that exact file natively. Routing m4a to AVFoundation
/// keeps the "every format" promise AND makes the common cases bulletproof.
final class HybridEngine: AudioEngine {

    private let avEngine = AVFoundationEngine()
    #if canImport(VLCKit)
    private let vlcEngine = VLCEngine()
    #endif

    /// Backend that will receive playback commands (set by `load`).
    private var active: AudioEngine

    init() {
        #if canImport(VLCKit)
        active = vlcEngine
        #else
        active = avEngine
        #endif
    }

    var onEndReached: (() -> Void)? {
        get { active.onEndReached }
        set {
            // Wire both backends so the closure survives an engine swap.
            avEngine.onEndReached = newValue
            #if canImport(VLCKit)
            vlcEngine.onEndReached = newValue
            #endif
        }
    }

    var isPlaying: Bool { active.isPlaying }
    var currentTime: TimeInterval { active.currentTime }
    var duration: TimeInterval { active.duration }

    var volume: Float {
        get { active.volume }
        set {
            avEngine.volume = newValue
            #if canImport(VLCKit)
            vlcEngine.volume = newValue
            #endif
        }
    }

    func load(url: URL) {
        active = Self.backend(for: url, avEngine: avEngine, vlcEngine: vlcEngineAvailable)
        active.load(url: url)
    }

    func play() { active.play() }
    func pause() { active.pause() }

    func stop() {
        avEngine.stop()
        #if canImport(VLCKit)
        vlcEngine.stop()
        #endif
    }

    func seek(to time: TimeInterval) { active.seek(to: time) }

    // MARK: - Backend selection

    /// Extensions AVFoundation decodes natively (iOS 15).
    private static let avNativeExtensions: Set<String> = [
        "mp3", "m4a", "m4b", "aac", "alac", "flac",
        "wav", "aif", "aiff", "caf", "mp4"
    ]

    private var vlcEngineAvailable: AudioEngine? {
        #if canImport(VLCKit)
        return vlcEngine
        #else
        return nil
        #endif
    }

    private static func backend(for url: URL, avEngine: AudioEngine, vlcEngine: AudioEngine?) -> AudioEngine {
        let ext = url.pathExtension.lowercased()
        if avNativeExtensions.contains(ext) {
            return avEngine
        }
        return vlcEngine ?? avEngine
    }
}
