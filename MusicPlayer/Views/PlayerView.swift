import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var player: PlayerManager
    @State private var scrubValue: Double?
    @State private var isScrubbing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.13, green: 0.10, blue: 0.25), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)

                if let track = player.currentTrack {
                    ArtworkView(url: track.artworkURL, size: 300)
                    VStack(spacing: 6) {
                        Text(track.title)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Text(track.artist)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        if let album = track.album {
                            Text(album)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    progressSection
                    controls
                    volumeSection
                } else {
                    Text("Nothing playing")
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
        }
    }

    private var displayedTime: Double {
        isScrubbing ? (scrubValue ?? player.currentTime) : player.currentTime
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { displayedTime },
                    set: { scrubValue = $0 }
                ),
                in: 0...max(player.duration, 1),
                onEditingChanged: { editing in
                    isScrubbing = editing
                    if !editing {
                        player.seek(to: scrubValue ?? player.currentTime)
                        scrubValue = nil
                    }
                }
            )
            .tint(.white)
            HStack {
                Text(formatTime(displayedTime))
                Spacer()
                Text(player.duration > 0 ? formatTime(player.duration) : "--:--")
            }
            .font(.caption.monospacedDigit())
            .foregroundColor(.white.opacity(0.6))
        }
    }

    private var controls: some View {
        HStack(spacing: 36) {
            Button {
                player.shuffle.toggle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.title2)
                    .foregroundColor(player.shuffle ? .white : .white.opacity(0.4))
            }
            Button {
                player.previous()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.white)
            }
            Button {
                player.next()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Button {
                cycleRepeat()
            } label: {
                Image(systemName: repeatIcon)
                    .font(.title2)
                    .foregroundColor(player.repeatMode == .off ? .white.opacity(0.4) : .white)
            }
        }
    }

    private var volumeSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .foregroundColor(.white.opacity(0.6))
            Slider(
                value: Binding(
                    get: { Double(player.volume) },
                    set: { player.setVolume(Float($0)) }
                ),
                in: 0...1
            )
            .tint(.white)
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private var repeatIcon: String {
        switch player.repeatMode {
        case .off, .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    private func cycleRepeat() {
        let next = (player.repeatMode.rawValue + 1) % 3
        player.repeatMode = PlayerManager.RepeatMode(rawValue: next) ?? .off
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "0:00" }
        let total = Int(time)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
