import AVFoundation
import Combine
import Foundation
import MediaPlayer
import UIKit
import CoreHaptics

/// Central playback state machine: owns the queue, the audio engine,
/// remote-control / lock-screen integration and the background audio session.
final class PlayerManager: ObservableObject {

    static let shared = PlayerManager()

    enum RepeatMode: Int {
        case off = 0, all = 1, one = 2
    }

    // MARK: - Published state

    @Published var queue: [Track] = []
    @Published private(set) var currentIndex: Int?
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var shuffle = false
    @Published var repeatMode: RepeatMode = .off
    @Published var volume: Float = 0.8
    @Published var isLoading = false
    @Published var sleepTimerRemaining: TimeInterval?
    @Published private(set) var isBuffering = false
    
    var currentTrack: Track? {
        guard let index = currentIndex, queue.indices.contains(index) else { return nil }
        return queue[index]
    }
    
    // MARK: - Haptic Engine
    
    private var hapticEngine: CHHapticEngine?
    
    private func setupHaptics() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine unavailable: \(error)")
        }
    }
    
    func triggerHaptic(_ pattern: HapticPattern = .mediumTap) {
        guard let engine = hapticEngine else { return }
        
        let intensity: CGFloat
        switch pattern {
        case .lightTap: intensity = 0.3
        case .mediumTap: intensity = 0.5
        case .heavyTap: intensity = 0.8
        case .success: intensity = 0.6
        case .warning: intensity = 0.4
        }
        
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticParameter(parameterID: .hapticIntensity, value: Float(intensity)),
            CHHapticParameter(parameterID: .hapticSharpness, value: 0.5)
        ], relativeTime: 0, duration: 0.15)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error)")
        }
    }
    
    enum HapticPattern {
        case lightTap, mediumTap, heavyTap, success, warning
    }

    // MARK: - Private

    private let engine: AudioEngine = AudioEngineFactory.make()
    private var timer: Timer?
    private var pendingAutoAdvance = false
    private var sleepTimer: Timer?

    private init() {
        configureAudioSession()
        setupRemoteCommands()
        startTimer()
        setupHaptics()
        engine.onEndReached = { [weak self] in self?.handleEndReached() }
        observeEngineState()
    }
    
    private func observeEngineState() {
        // Observe loading/buffering states from engine
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("EngineDidStartLoading"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLoading = true
            self?.isBuffering = true
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("EngineDidFinishLoading"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLoading = false
            self?.isBuffering = false
        }
    }
    
    // MARK: - Sleep Timer
    
    func startSleepTimer(minutes: Int) {
        stopSleepTimer()
        let seconds = TimeInterval(minutes * 60)
        sleepTimerRemaining = seconds
        
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if let remaining = self.sleepTimerRemaining, remaining > 1 {
                self.sleepTimerRemaining = remaining - 1
            } else {
                timer.invalidate()
                self.sleepTimerRemaining = nil
                self.pause()
                self.triggerHaptic(.success)
            }
        }
    }
    
    func stopSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerRemaining = nil
    }
    
    func toggleSleepTimer() {
        if sleepTimerRemaining != nil {
            stopSleepTimer()
        } else {
            startSleepTimer(minutes: 30)
        }
    }

    // MARK: - Playback controls

    func play(tracks: [Track], startAt index: Int) {
        guard !tracks.isEmpty else { return }
        queue = tracks
        currentIndex = min(max(index, 0), tracks.count - 1)
        triggerHaptic(.mediumTap)
        startCurrent()
    }

    func togglePlayPause() {
        triggerHaptic(.mediumTap)
        isPlaying ? pause() : resume()
    }

    func resume() {
        guard currentTrack != nil else { return }
        engine.play()
        isPlaying = true
        updateNowPlaying()
    }

    func pause() {
        engine.pause()
        isPlaying = false
        updateNowPlaying()
    }

    func next() {
        triggerHaptic(.lightTap)
        step(+1, userInitiated: true)
    }

    func previous() {
        triggerHaptic(.lightTap)
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        step(-1, userInitiated: true)
    }

    func seek(to time: TimeInterval) {
        let clamped = max(0, time)
        engine.seek(to: clamped)
        currentTime = clamped
        updateNowPlaying()
    }

    func setVolume(_ value: Float) {
        volume = min(max(value, 0), 1)
        engine.volume = volume
    }

    // MARK: - Internals

    private func startCurrent() {
        guard let track = currentTrack else { return }
        pendingAutoAdvance = false
        isLoading = true
        engine.load(url: track.url)
        engine.volume = volume
        engine.play()
        isPlaying = true
        currentTime = 0
        duration = 0
        updateNowPlaying()
    }

    private func step(_ delta: Int, userInitiated: Bool) {
        guard !queue.isEmpty else { return }
        let base = currentIndex ?? 0

        // Repeat-one: a natural end replays the current track.
        if repeatMode == .one && !userInitiated {
            engine.seek(to: 0)
            engine.play()
            isPlaying = true
            currentTime = 0
            updateNowPlaying()
            return
        }

        var index: Int
        if shuffle && delta > 0 {
            index = randomNextIndex()
        } else {
            index = base + delta
        }

        if index >= queue.count {
            if repeatMode == .all {
                index = 0
            } else if userInitiated {
                return // already on the last track — stay put
            } else {
                pause() // natural end + repeat off → stop
                engine.seek(to: 0)
                currentTime = 0
                return
            }
        } else if index < 0 {
            index = queue.count - 1
        }

        currentIndex = index
        startCurrent()
    }

    private func randomNextIndex() -> Int {
        guard queue.count > 1 else { return currentIndex ?? 0 }
        var random = Int.random(in: 0..<queue.count)
        if random == (currentIndex ?? 0) {
            random = (random + 1) % queue.count
        }
        return random
    }

    private func handleEndReached() {
        guard !pendingAutoAdvance else { return }
        pendingAutoAdvance = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pendingAutoAdvance = false
            self.step(+1, userInitiated: false)
        }
    }

    private func startTimer() {
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        guard currentTrack != nil else { return }
        duration = engine.duration
        currentTime = engine.currentTime
        syncPlayingState()
    }

    private func syncPlayingState() {
        let actual = engine.isPlaying
        if isPlaying != actual {
            isPlaying = actual
            if actual { updateNowPlaying() }
        }
    }

    // MARK: - Audio session & lock screen

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let commandEvent = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: commandEvent.positionTime)
            }
            return .success
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    private func updateNowPlaying() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyPlaybackDuration: duration > 0 ? duration : 0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let album = track.album {
            info[MPMediaItemPropertyAlbumTitle] = album
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        loadArtwork(for: track) { artwork in
            var updated = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? info
            updated[MPMediaItemPropertyArtwork] = artwork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = updated
        }
    }

    private func loadArtwork(for track: Track, completion: @escaping (MPMediaItemArtwork) -> Void) {
        guard let url = track.artworkURL else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            DispatchQueue.main.async { completion(artwork) }
        }.resume()
    }
}
