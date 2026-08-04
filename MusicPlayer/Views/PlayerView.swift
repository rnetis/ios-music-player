import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var player: PlayerManager
    @State private var scrubValue: Double?
    @State private var isScrubbing = false
    @State private var artworkScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Luxurious animated gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.10, blue: 0.30),
                    Color(red: 0.05, green: 0.02, blue: 0.10),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle mesh gradient overlay for depth
            RadialGradient(
                colors: [Color.purple.opacity(0.15), .clear],
                center: .topLeading,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color.blue.opacity(0.1), .clear],
                center: .bottomTrailing,
                startRadius: 150,
                endRadius: 450
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                // Modern handle indicator
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                if let track = player.currentTrack {
                    // Enhanced artwork with shadow and scale animation
                    ArtworkView(url: track.artworkURL, size: 320)
                        .scaleEffect(artworkScale)
                        .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    // Track info with modern typography
                    VStack(spacing: 8) {
                        Text(track.title)
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text(track.artist)
                            .font(.title3.weight(.medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                        
                        if let album = track.album {
                            Text(album)
                                .font(.subheadline.weight(.regular))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    progressSection
                    controls
                    volumeSection
                } else {
                    // Enhanced empty state
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 120, height: 120)
                            Image(systemName: "music.note")
                                .font(.system(size: 50, weight: .ultraLight))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Text("Nothing playing")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
        }
        .onChange(of: player.isPlaying) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                artworkScale = newValue ? 1.0 : 0.95
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                artworkScale = player.isPlaying ? 1.0 : 0.95
            }
        }
    }

    private var displayedTime: Double {
        isScrubbing ? (scrubValue ?? player.currentTime) : player.currentTime
    }

    private var progressSection: some View {
        VStack(spacing: 10) {
            // Custom styled slider
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
            .tint(
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .animation(.easeInOut(duration: 0.2), value: displayedTime)
            
            HStack {
                Text(formatTime(displayedTime))
                Spacer()
                Text(player.duration > 0 ? formatTime(player.duration) : "--:--")
            }
            .font(.caption2.monospacedDigit())
            .foregroundColor(.white.opacity(0.5))
            .fontWeight(.medium)
        }
    }

    private var controls: some View {
        HStack(spacing: 40) {
            // Shuffle button with modern styling and glow
            Button {
                withAnimation(.spring(response: 0.3)) {
                    player.shuffle.toggle()
                }
                player.triggerHaptic(.lightTap)
            } label: {
                ZStack {
                    Circle()
                        .fill(player.shuffle ? Color.purple.opacity(0.2) : Color.clear)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "shuffle")
                        .font(.title3.weight(.medium))
                        .foregroundColor(player.shuffle ? .white : .white.opacity(0.3))
                        .shadow(color: player.shuffle ? .purple.opacity(0.5) : .clear, radius: 8, x: 0, y: 4)
                }
                .frame(width: 44, height: 44)
            }
            .scaleEffect(player.shuffle ? 1.1 : 1.0)
            
            // Previous button with hover effect
            Button {
                player.previous()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "backward.fill")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
            .scaleEffect(0.95)
            
            // Play/Pause button - enlarged and enhanced with pulsing glow
            Button {
                player.togglePlayPause()
            } label: {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 96, height: 96)
                        .blur(radius: 2)
                    
                    // Main button circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: .purple.opacity(0.5), radius: 25, x: 0, y: 12)
                    
                    // Loading indicator overlay
                    if player.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.6)
                    }
                    
                    // Icon
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 76))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(player.isPlaying ? 1.0 : 0.98)
                .animation(.spring(response: 0.2), value: player.isPlaying)
            }
            .disabled(player.isLoading)
            
            // Next button with hover effect
            Button {
                player.next()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "forward.fill")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
            .scaleEffect(0.95)
            
            // Sleep Timer button
            Button {
                player.toggleSleepTimer()
            } label: {
                ZStack {
                    Circle()
                        .fill(player.sleepTimerRemaining != nil ? Color.purple.opacity(0.2) : Color.clear)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: player.sleepTimerRemaining != nil ? "moon.fill" : "moon")
                        .font(.title3.weight(.medium))
                        .foregroundColor(player.sleepTimerRemaining != nil ? .white : .white.opacity(0.3))
                        .shadow(color: player.sleepTimerRemaining != nil ? .purple.opacity(0.5) : .clear, radius: 8, x: 0, y: 4)
                }
                .frame(width: 44, height: 44)
                .overlay(
                    Group {
                        if player.sleepTimerRemaining != nil {
                            Text(formatSleepTime(player.sleepTimerRemaining ?? 0))
                                .font(.caption2.monospacedDigit())
                                .foregroundColor(.white)
                                .offset(y: 22)
                        }
                    }
                )
            }
            .scaleEffect(player.sleepTimerRemaining != nil ? 1.1 : 1.0)
            .animation(.spring(response: 0.3), value: player.sleepTimerRemaining)
            
            // Repeat button with modern styling and glow
            Button {
                withAnimation(.spring(response: 0.3)) {
                    cycleRepeat()
                }
                player.triggerHaptic(.lightTap)
            } label: {
                ZStack {
                    Circle()
                        .fill(player.repeatMode != .off ? Color.purple.opacity(0.2) : Color.clear)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: repeatIcon)
                        .font(.title3.weight(.medium))
                        .foregroundColor(player.repeatMode == .off ? .white.opacity(0.3) : .white)
                        .shadow(color: player.repeatMode != .off ? .purple.opacity(0.5) : .clear, radius: 8, x: 0, y: 4)
                }
                .frame(width: 44, height: 44)
            }
            .scaleEffect(player.repeatMode != .off ? 1.1 : 1.0)
        }
    }

    private var volumeSection: some View {
        HStack(spacing: 14) {
            Image(systemName: "speaker.fill")
                .foregroundColor(.white.opacity(0.5))
                .font(.caption)
            
            // Custom volume slider with enhanced gradient
            Slider(
                value: Binding(
                    get: { Double(player.volume) },
                    set: { player.setVolume(Float($0)) }
                ),
                in: 0...1
            )
            .tint(
                LinearGradient(
                    colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(maxWidth: 140)
            
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(.white.opacity(0.5))
                .font(.caption)
        }
        .padding(.horizontal, 8)
        
        // Now Playing bar indicator at bottom
        if let track = player.currentTrack {
            VStack(spacing: 4) {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                HStack {
                    ArtworkView(url: track.artworkURL, size: 40)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Mini visualizer
                    if player.isPlaying {
                        HStack(spacing: 2) {
                            ForEach(0..<4) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(width: 3, height: CGFloat(10 + (i % 3) * 4))
                                    .animation(
                                        Animation.easeInOut(duration: 0.4)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.1),
                                        value: player.isPlaying
                                    )
                            }
                        }
                        .padding(.trailing, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .padding(.top, 8)
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
    
    private func formatSleepTime(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "" }
        let total = Int(time)
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
