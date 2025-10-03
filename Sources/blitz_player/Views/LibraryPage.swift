import SwiftUI

struct LibraryPage: View {
    @ObservedObject var songManager: SongManager
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var selectedSong: Song?

    var body: some View {
        List {
            NavigationLink {
                ArtistsView(
                    songs: songManager.songs, audioPlayer: audioPlayer,
                    selectedSong: $selectedSong
                )
                .navigationTitle("Artists")
            } label: {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.primary)
                    Text("Artists")
                }
            }
            NavigationLink {
                AlbumsView(
                    songs: songManager.songs, audioPlayer: audioPlayer,
                    selectedSong: $selectedSong
                )
                .navigationTitle("Albums")
            } label: {
                HStack {
                    Image(systemName: "square.stack.fill")
                        .foregroundColor(.primary)
                    Text("Albums")
                }
            }
            NavigationLink {
                GenresView(
                    songs: songManager.songs, audioPlayer: audioPlayer,
                    selectedSong: $selectedSong
                )
                .navigationTitle("Genres")
            } label: {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.primary)
                    Text("Genres")
                }
            }
        }
    }
}