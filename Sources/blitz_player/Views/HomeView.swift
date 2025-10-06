import AVFoundation
import SwiftUI
import UIKit

struct ContentView: View {
  @ObservedObject var songManager: SongManager
  @ObservedObject var audioPlayer: AudioPlayer
  @Binding var selectedSong: Song?
  @State private var showingPicker = false
  @State private var pickedFolder: URL?
  @State private var loadedArtworks: [UUID: UIImage] = [:]

  static func loadArtwork(from url: URL) async -> UIImage? {
    let asset = AVURLAsset(url: url)
    if #available(iOS 16.0, *) {
      do {
        let formats: [AVMetadataFormat] = [
          .id3Metadata, .iTunesMetadata, .quickTimeMetadata,
        ]
        for format in formats {
          let metadata = try await asset.loadMetadata(for: format)
          for item in metadata {
            if item.commonKey == .commonKeyArtwork,
              let data = try await item.load(.dataValue),
              let image = UIImage(data: data)
            {
              return image
            }
          }
        }
      } catch {
        // Ignore and fall back to nil
      }
      return nil
    } else {
      // Fallback for iOS < 16
      let formats: [AVMetadataFormat] = [.id3Metadata, .iTunesMetadata, .quickTimeMetadata]
      for format in formats {
        let metadata = asset.metadata(forFormat: format)
        for item in metadata {
          if item.commonKey == .commonKeyArtwork, let data = item.dataValue,
            let image = UIImage(data: data)
          {
            return image
          }
        }
      }
      return nil
    }
  }

  var body: some View {
    if !songManager.songs.isEmpty {
      ScrollView {
        LazyVGrid(
          columns: [
            GridItem(.adaptive(minimum: 150, maximum: 200)),
            GridItem(.adaptive(minimum: 150, maximum: 200)),
          ], spacing: 16
        ) {
          ForEach(songManager.songs) { song in
            VStack(alignment: .leading, spacing: 8) {
              if let artwork = song.artwork ?? loadedArtworks[song.id] {
                Image(uiImage: artwork)
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(width: 150, height: 150)
                  .cornerRadius(8)
                  .shadow(radius: 4)
              } else {
                ArtworkImage(url: song.url, size: 150)
                  .onAppear {
                    Task {
                      if loadedArtworks[song.id] == nil {
                        let artwork = await Self.loadArtwork(from: song.url)
                        await MainActor.run {
                          loadedArtworks[song.id] = artwork
                        }
                      }
                    }
                  }
              }
              HStack {
                Text(song.name)
              }
            }
            .padding()
            .frame(width: 170, height: 220)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
              selectedSong = song
              audioPlayer.startPlayback(url: song.url)
            }
            .padding()
          }
          .padding()
        }
      }
    } else {
      ContentUnavailableView {
        Label("No Songs Found", systemImage: "music.note")
      } description: {
        Text("Please press \"Open Folder\" to load songs from a folder")
      }
    }
  }
}
