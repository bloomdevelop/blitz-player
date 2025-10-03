import SwiftUI

struct LibraryPage: View {
    @ObservedObject var songManager: SongManager
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var selectedSong: Song?

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Artists") {
                    ArtistsView(
                        songs: songManager.songs, audioPlayer: audioPlayer,
                        selectedSong: $selectedSong)
                }
                NavigationLink("Albums") {
                    AlbumsView(
                        songs: songManager.songs, audioPlayer: audioPlayer,
                        selectedSong: $selectedSong)
                }
                NavigationLink("Genres") {
                    GenresView(
                        songs: songManager.songs, audioPlayer: audioPlayer,
                        selectedSong: $selectedSong)
                }
            }
        }
        .navigationTitle("Library")
    }
}

struct ArtistsView: View {
    let songs: [Song]
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var selectedSong: Song?

    var grouped: [String: [Song]] {
        Dictionary(grouping: songs, by: { $0.artist ?? "Unknown Artist" })
    }

    var body: some View {
        List {
            ForEach(grouped.keys.sorted(), id: \.self) { artist in
                NavigationLink(
                    destination: SongsListView(
                        songs: grouped[artist] ?? [], audioPlayer: audioPlayer,
                        selectedSong: $selectedSong)
                ) {
                    Text(artist)
                }
            }
        }
    }
}

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
                        destination: SongsListView(
                            songs: albumSongs, audioPlayer: audioPlayer, selectedSong: $selectedSong
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            if let artwork = artwork {
                                Image(uiImage: artwork)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(8)
                                    .shadow(radius: 4)
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
                            Text(album)
                                .font(.headline)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct GenresView: View {
    let songs: [Song]
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var selectedSong: Song?

    var grouped: [String: [Song]] {
        Dictionary(grouping: songs, by: { $0.genre ?? "Unknown Genre" })
    }

    var body: some View {
        List {
            ForEach(grouped.keys.sorted(), id: \.self) { genre in
                NavigationLink(
                    destination: SongsListView(
                        songs: grouped[genre] ?? [], audioPlayer: audioPlayer,
                        selectedSong: $selectedSong)
                ) {
                    Text(genre)
                }
            }
        }
    }
}

struct SongsListView: View {
    let songs: [Song]
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var selectedSong: Song?

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
        .navigationTitle("Songs")
    }
}
