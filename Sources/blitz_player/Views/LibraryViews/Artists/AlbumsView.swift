import SwiftUI

struct AlbumsView: View {
    let songs: [Song]
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var selectedSong: Song?

    var grouped: [String: [Song]] {
        Dictionary(grouping: songs, by: { $0.album ?? "Unknown Album" })
    }

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 150, maximum: 200)),
                    GridItem(.adaptive(minimum: 150, maximum: 200)),
                ], spacing: 16
            ) {
                ForEach(grouped.keys.sorted(), id: \.self) { album in
                    let albumSongs = grouped[album] ?? []
                    let artwork = albumSongs.first(where: { $0.artwork != nil })?.artwork
                    NavigationLink(
                        destination: AlbumSongsListView(
                            songs: albumSongs, albumName: album, albumArtwork: artwork, audioPlayer: audioPlayer,
                            selectedSong: $selectedSong
                        )
                    ) {
                        VStack(alignment: .center, spacing: 8) {
                            if let artwork = artwork {
                                Image(uiImage: artwork)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(8)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 150, height: 150)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                            }

                            Spacer()

                            Text(album)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(width: .infinity, height: .infinity)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
                }
            }
            .padding()
        }
    }
}