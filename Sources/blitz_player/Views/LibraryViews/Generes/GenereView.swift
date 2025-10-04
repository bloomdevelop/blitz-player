import SwiftUI

struct GenereView: View {
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
    }
}