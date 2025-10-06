import SwiftUI

struct MiniPlayerComponent: View {

  @ObservedObject var audioPlayer: AudioPlayer
  var song: Song?
  var navNamespace: Namespace.ID
  @State private var artworkURL: URL? = nil

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

        ReplacableIconButton(
          prevIcon: "play.fill",
          nextIcon: "pause.fill",
          isSwitched: $audioPlayer.isPlaying,
          action: {
            audioPlayer.togglePlayback()
          },
          size: 40,
          color: .primary
        )

        IconButton(
          icon: "forward.fill",
          action: {
            // TODO)) Next/prev track
          },
          size: 40,
          color: .primary
        )
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
