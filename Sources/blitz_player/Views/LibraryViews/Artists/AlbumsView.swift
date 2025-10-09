import SwiftUI

struct AlbumsView: View {
  let songs: [Song]
  @ObservedObject var audioPlayer: AudioPlayer
  @ObservedObject var songManager: SongManager
  @Binding var selectedSong: Song?
  @State private var grouped: [String: [Song]] = [:]

  var body: some View {
    let albumNames: [String] = grouped.keys.sorted()
    ScrollView {
      LazyVGrid(
        columns: [
          GridItem(.adaptive(minimum: 150, maximum: 200)),
          GridItem(.adaptive(minimum: 150, maximum: 200)),
        ], spacing: 16
      ) {
        ForEach(albumNames, id: \.self) { album in
          let albumSongs = grouped[album] ?? []
          let artwork = albumSongs.first(where: { $0.artwork != nil })?.artwork
          NavigationLink(
            destination: AlbumSongsListView(
              songs: albumSongs, albumName: album, albumArtwork: artwork,
              audioPlayer: audioPlayer, songManager: songManager,
              selectedSong: $selectedSong
            )
          ) {
            VStack(alignment: .leading) {
              ArtworkImage(artwork, size: 150)
              Text(album)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
          }
        }
      }
      .padding()
    }
    .onChange(of: songs) {
      grouped = Dictionary(grouping: songs, by: { $0.album ?? "Unknown Album" })
    }
    .onAppear {
      if grouped.isEmpty {
        grouped = Dictionary(grouping: songs, by: { $0.album ?? "Unknown Album" })
      }
    }
  }
}
