import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var player: PlayerManager
    @Binding var showPlayer: Bool
    @State private var isHovering = false
    @State private var waveHeights: [CGFloat] = [8, 12, 6, 10, 7]
    
    var body: some View {
        if let track = player.currentTrack {
            HStack(spacing: 14) {
                // Enhanced artwork with shadow and scale
                ArtworkView(url: track.artworkURL, size: 52)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .scaleEffect(isHovering ? 1.05 : 1.0)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .foregroundColor(.white)
                    Text(track.artist)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    // Enhanced playing indicator with more bars
                    if player.isPlaying {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .blue, .purple],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(width: 2.5, height: waveHeights[i])
                                    .animation(
                                        Animation.easeInOut(duration: 0.5 + Double(i) * 0.1)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.1),
                                        value: player.isPlaying
                                    )
                            }
                        }
                        .padding(.top, 3)
                    }
                }
                
                Spacer()
                
                // Skip back button
                Button {
                    player.previous()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .accessibilityLabel("Previous Track")
                
                // Modern play/pause button with glow
                Button {
                    player.togglePlayPause()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                        
                        // Loading indicator
                        if player.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.5)
                        }
                        
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
                .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                .disabled(player.isLoading)
                
                // Next button
                Button {
                    player.next()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "goforward.15")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .accessibilityLabel("Next Track")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.15, blue: 0.35).opacity(0.95),
                        Color(red: 0.1, green: 0.05, blue: 0.2).opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .purple.opacity(0.4), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .onTapGesture { showPlayer = true }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            .onChange(of: player.isPlaying) { isPlaying in
                if isPlaying {
                    // Animate wave heights when playing starts
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        waveHeights = [12, 6, 14, 8, 10]
                    }
                } else {
                    waveHeights = [8, 12, 6, 10, 7]
                }
            }
        }
    }
}
