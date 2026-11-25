import AVKit
import DinnertimeKit
import SwiftUI

/// Where a recipe comes from: the copy of its video the server keeps, played in the app, and the link to the original.
///
/// The copy is streamed from the server, so it needs a connection.
struct RecipeSourceLinks: View {
    let recipe: Recipe

    @State private var playsVideo = false
    @Environment(AppSession.self) private var session

    var body: some View {
        if let video = recipe.videoURL {
            Button("Watch video", systemImage: "play.rectangle") {
                playsVideo = true
            }
            .fullScreenCover(isPresented: $playsVideo) {
                RecipeVideoPlayer(url: session.absoluteURL(for: video))
            }
        }
        if let url = recipe.sourceURL {
            Link(destination: url) {
                Label("View original", systemImage: "safari")
            }
        }
    }
}

/// Plays the kept video of a recipe across the screen, with a button that closes it.
private struct RecipeVideoPlayer: View {
    @State private var player: AVPlayer
    @Environment(\.dismiss) private var dismiss

    init(url: URL) {
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .background(.black)
            .overlay(alignment: .topLeading) {
                Button("Close", systemImage: "xmark") {
                    dismiss()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
                .padding()
            }
            .onAppear {
                player.play()
            }
            .onDisappear {
                player.pause()
            }
    }
}
