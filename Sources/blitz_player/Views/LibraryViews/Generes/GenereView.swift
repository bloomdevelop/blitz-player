import SwiftUI

struct GenereView: View {
  let songs: [Song]
  let genereName: String
  @ObservedObject var audioPlayer: AudioPlayer
  @Binding var selectedSong: Song?
  @EnvironmentObject var songManager: SongManager

  var body: some View {
    List(songs) { song in
      HStack {
        if let artwork = song.artwork {
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
        audioPlayer.startPlayback(url: song.url)
      }
    }
    .navigationTitle(genereName)
  }
}
