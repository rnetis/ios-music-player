import Foundation

/// Abstraction over the actual audio engine so we can use VLCKit
/// (plays every format) when it is available, and fall back to
/// AVFoundation otherwise.
protocol AudioEngine: AnyObject {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var volume: Float { get set }
    var onEndReached: (() -> Void)? { get set }
    func load(url: URL)
    func play()
    func pause()
    func stop()
    func seek(to time: TimeInterval)
}

enum AudioEngineFactory {
    static func make() -> AudioEngine {
        #if canImport(VLCKit)
        return VLCEngine()
        #else
        return AVFoundationEngine()
        #endif
    }
}
