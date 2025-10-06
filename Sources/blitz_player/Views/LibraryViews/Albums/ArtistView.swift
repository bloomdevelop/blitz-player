import AVFoundation
import SwiftUI

struct ArtistSongsListView: View {
  let songs: [Song]
  let artistName: String
  @ObservedObject var audioPlayer: AudioPlayer
  @Binding var selectedSong: Song?

  @State private var loadedArtworks: [UUID: UIImage?] = [:]

  var body: some View {
    List(songs) { song in
      HStack {
        if let stored = loadedArtworks[song.id], let artwork = stored {
          Image(uiImage: artwork)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 50, height: 50)
            .cornerRadius(4)
        } else {
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray.opacity(0.3))
            .frame(width: 50, height: 50)
            .overlay(
              Image(systemName: "music.note")
                .foregroundColor(.gray)
            )
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
        audioPlayer.startPlayback(url: song.url)
      }
      .onAppear {
        guard loadedArtworks[song.id] == nil else { return }
        Task {
          let url = song.url
          let asset = AVURLAsset(url: url)
          var artwork: UIImage? = nil
          if #available(iOS 16.0, *) {
            do {
              let formats: [AVMetadataFormat] = [.id3Metadata, .iTunesMetadata, .quickTimeMetadata]
              for format in formats {
                let metadata = try await asset.loadMetadata(for: format)
                for item in metadata {
                  if item.commonKey == .commonKeyArtwork,
                    let data = try await item.load(.dataValue),
                    let image = UIImage(data: data)
                  {
                    artwork = image
                    break
                  }
                }
                if artwork != nil { break }
              }
            } catch {
              // Ignore and fall back to nil
            }
            await MainActor.run {
              loadedArtworks[song.id] = artwork
            }
          } else {
            // Fallback for iOS < 16
            let formats: [AVMetadataFormat] = [.id3Metadata, .iTunesMetadata, .quickTimeMetadata]
            for format in formats {
              let metadata = asset.metadata(forFormat: format)
              for item in metadata {
                if item.commonKey == .commonKeyArtwork,
                  let data = item.dataValue,
                  let image = UIImage(data: data)
                {
                  artwork = image
                  break
                }
              }
              if artwork != nil { break }
            }
            await MainActor.run {
              loadedArtworks[song.id] = artwork
            }
          }
        }
      }
    }
    .navigationTitle(artistName)
  }
}
