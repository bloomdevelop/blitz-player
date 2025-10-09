import SwiftUI
import UIKit

struct MiniPlayerComponent: View {

   @ObservedObject var audioPlayer: AudioPlayer
   @ObservedObject var songManager: SongManager
   @Binding var selectedSong: Song?
   var song: Song?
   var navNamespace: Namespace.ID
   @State private var artworkURL: URL? = nil
   @State private var previousButtonScale: CGFloat = 1.0
   @State private var playButtonScale: CGFloat = 1.0
   @State private var nextButtonScale: CGFloat = 1.0

  var body: some View {
    if let song = song {
      HStack {
        if let artwork = song.artwork {
          if let artURL = artworkURL {
            ArtworkImage(url: artURL, size: 40)
              .matchedGeometryEffect(id: "albumArt", in: navNamespace)
          } else {
            Image(uiImage: artwork)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 40, height: 40)
              .cornerRadius(6)
              .matchedGeometryEffect(id: "albumArt", in: navNamespace)
              .onAppear {
                // If we already have a UIImage, write it out to a temporary file once
                // so `ArtworkImage` (which uses AsyncImage) can reuse the same loading / placeholder UI.
                // This is a lightweight approach and the temp file is created only once per view lifecycle.
                if artworkURL == nil {
                  if let data = artwork.pngData() {
                    let temp = FileManager.default.temporaryDirectory.appendingPathComponent(
                      "\(UUID().uuidString).png")
                    try? data.write(to: temp)
                    artworkURL = temp
                  }
                }
              }
          }
        } else {
          RoundedRectangle(cornerRadius: 6)
            .fill(.gray)
            .frame(width: 40, height: 40)
            .overlay(
              Image(systemName: "music.note")
                .tint(.accentColor)
                .opacity(0.5)
            )
            .matchedGeometryEffect(id: "albumArt", in: navNamespace)
        }

        VStack(alignment: .leading) {
          Text(song.name)
            .lineLimit(1)
            .font(.subheadline)
          Text("Now Playing")
            .font(.caption)
            .foregroundColor(.gray)
        }

        Spacer()

        IconButton(
          icon: "backward.fill",
          action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.easeInOut(duration: 0.1)) {
              previousButtonScale = 0.9
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              withAnimation(.easeInOut(duration: 0.1)) {
                previousButtonScale = 1.0
              }
            }
            audioPlayer.playPrevious()
          },
          size: 40,
          color: .primary
        )
        .disabled((songManager.queue.isEmpty ? songManager.songs.count : songManager.queue.count) <= 1)
        .scaleEffect(previousButtonScale)

        ReplacableIconButton(
          prevIcon: "play.fill",
          nextIcon: "pause.fill",
          isSwitched: $audioPlayer.isPlaying,
          action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.easeInOut(duration: 0.1)) {
              playButtonScale = 0.9
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              withAnimation(.easeInOut(duration: 0.1)) {
                playButtonScale = 1.0
              }
            }
            audioPlayer.togglePlayback()
          },
          size: 40,
          color: .primary
        )
        .scaleEffect(playButtonScale)

        IconButton(
          icon: "forward.fill",
          action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.easeInOut(duration: 0.1)) {
              nextButtonScale = 0.9
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              withAnimation(.easeInOut(duration: 0.1)) {
                nextButtonScale = 1.0
              }
            }
            audioPlayer.playNext()
          },
          size: 40,
          color: .primary
        )
        .disabled((songManager.queue.isEmpty ? songManager.songs.count : songManager.queue.count) <= 1)
        .scaleEffect(nextButtonScale)
      }
      .padding(10)
      .background(.bar)
      .cornerRadius(12)
      .padding(.horizontal)
      .shadow(radius: 4)
    } else {
      HStack {
        RoundedRectangle(cornerRadius: 6)
          .fill(.gray)
          .frame(width: 40, height: 40)
          .overlay(
            Image(systemName: "music.note")
              .tint(.accentColor)
              .opacity(0.5)
          )

        VStack(alignment: .leading) {
          Text("No Song Selected")
            .lineLimit(1)
            .font(.subheadline)
            .foregroundColor(.secondary)
          Text("Choose a track to play")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        IconButton(
          icon: "play.fill",
          action: {},
          size: 40,
          color: .primary
        )

        IconButton(
          icon: "forward.fill",
          action: {},
          size: 40,
          color: .primary
        )
      }
      .padding(10)
      .background(.bar)
      .cornerRadius(12)
      .padding(.horizontal)
      .shadow(radius: 4)
    }
  }
}
