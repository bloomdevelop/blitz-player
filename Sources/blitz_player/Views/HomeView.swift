import SwiftUI

struct ContentView: View {
    @ObservedObject var songManager: SongManager
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var selectedSong: Song?
    @State private var showingPicker = false
    @State private var pickedFolder: URL?

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
                            if let artwork = song.artwork {
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
