import SwiftUI

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
                    destination: GenereView(
                        songs: grouped[genre] ?? [], audioPlayer: audioPlayer,
                        selectedSong: $selectedSong)
                ) {
                    Text(genre)
                }
            }
        }
    }
}