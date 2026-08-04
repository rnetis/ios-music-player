import SwiftUI

@main
struct MusicPlayerApp: App {
    @StateObject private var player = PlayerManager.shared

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(player)
                .preferredColorScheme(.dark)
        }
    }
}
