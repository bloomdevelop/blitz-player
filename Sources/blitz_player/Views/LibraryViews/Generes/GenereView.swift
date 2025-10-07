import SwiftUI
import UIKit

struct GenereView: View {
  let songs: [Song]
  let genereName: String
  @ObservedObject var audioPlayer: AudioPlayer
  @Binding var selectedSong: Song?
  @EnvironmentObject var songManager: SongManager

  // Helper: write a UIImage to a temporary file and return its file URL.
  // ArtworkImage uses an URL with AsyncImage, so for locally-loaded UIImages
  // we write them to a temp file and pass the file URL to `ArtworkImage`.
  private func tempURL(for image: UIImage) -> URL? {
    // Prefer JPEG, fall back to PNG
    guard let data = image.jpegData(compressionQuality: 0.9) ?? image.pngData() else {
      return nil
    }
    let filename = UUID().uuidString + ".jpg"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    do {
      try data.write(to: url, options: .atomic)
      return url
    } catch {
      return nil
    }
  }

  var body: some View {
    List(songs) { song in
      HStack {
        if let artwork = song.artwork {
          // Try to convert the in-memory UIImage to a temporary file URL and
          // use `ArtworkImage` (which uses `AsyncImage`) to render it.
          if let url = tempURL(for: artwork) {
            ArtworkImage(url: url, size: 50)
              .frame(width: 50, height: 50)
              .cornerRadius(4)
          } else {
            // Fallback to the previous direct UIImage rendering if writing to disk fails
            Image(uiImage: artwork)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 50, height: 50)
              .cornerRadius(4)
          }
        } else {
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray.opacity(0.3))
            .frame(width: 50, height: 50)
            .overlay(
              Image(systemName: "music.note")
                .foregroundColor(.gray)
            )
            .task {
              await songManager.loadArtwork(for: song.id)
            }
        }

        VStack(alignment: .leading) {
          Text(song.name)
            .font(.headline)
          if let artist = song.artist {
            Text(artist)
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
      }
      .contentShape(Rectangle())
      .onTapGesture {
        selectedSong = song
        audioPlayer.startPlayback(song: song)
      }
    }
    .navigationTitle(genereName)
  }
}
