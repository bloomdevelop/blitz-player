import SwiftUI

struct SearchView: View {
    @ObservedObject var songManager: SongManager
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var selectedSong: Song?

    @State private var searchText = ""

    var filteredSongs: [Song] {
        if searchText.isEmpty {
            return songManager.songs
        } else {
            return songManager.songs.filter { song in
                song.name.localizedCaseInsensitiveContains(searchText) ||
                (song.artist?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (song.album?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (song.genre?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        List(filteredSongs) { song in
            HStack {
                if let artwork = song.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                } else {
                    ArtworkImage(url: song.url, size: 50)
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
        .searchable(text: $searchText, prompt: "Search songs...")
        .navigationTitle("Search")
    }
}