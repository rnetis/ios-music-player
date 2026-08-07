import SwiftUI

struct TrackRow: View {
    let track: Track
    @EnvironmentObject var player: PlayerManager
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced artwork with shadow and scale animation
            ArtworkView(url: track.artworkURL, size: 56)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                .scaleEffect(isHovering ? 1.08 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(player.currentTrack?.id == track.id ? Color.purple.opacity(0.6) : Color.clear, lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.body.weight(player.currentTrack?.id == track.id ? .semibold : .medium))
                    .lineLimit(1)
                    .foregroundColor(player.currentTrack?.id == track.id ? .purple : .white)
                
                Text(track.artist)
                    .font(.subheadline.weight(.regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                if player.currentTrack?.id == track.id && player.isPlaying {
                    HStack(spacing: 3) {
                        ForEach(0..<3) { i in
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 3, height: CGFloat(8 + i * 3))
                                .animation(
                                    Animation.easeInOut(duration: 0.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.15),
                                    value: player.isPlaying
                                )
                        }
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Play indicator for current track
            if player.currentTrack?.id == track.id {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .opacity(player.isPlaying ? 1 : 0.5)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: isHovering ? [Color.purple.opacity(0.08), Color.blue.opacity(0.05)] : [Color.white.opacity(0.03), Color.white.opacity(0.03)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

struct ArtworkView: View {
    let url: URL?
    var size: CGFloat = 48
    
    var body: some View {
        Group {
            if let url = url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        fallback
                    case .empty:
                        ProgressView()
                            .tint(.purple)
                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
    
    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.2, green: 0.15, blue: 0.35), Color(red: 0.1, green: 0.08, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "music.note")
                .font(.system(size: size * 0.35, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}
