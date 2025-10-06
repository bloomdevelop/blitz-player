import SwiftUI

struct AlbumsView: View {
  let songs: [Song]
  @ObservedObject var audioPlayer: AudioPlayer
  @Binding var selectedSong: Song?
  @Namespace private var namespace

  var grouped: [String: [Song]] {
    Dictionary(grouping: songs, by: { $0.album ?? "Unknown Album" })
  }

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
              audioPlayer: audioPlayer,
              selectedSong: $selectedSong,
              namespace: namespace
            )
          ) {
            VStack(alignment: .leading) {
              ArtworkImage(artwork, size: 150)
                .matchedTransitionSource(id: "album", in: namespace)
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
  }
}
