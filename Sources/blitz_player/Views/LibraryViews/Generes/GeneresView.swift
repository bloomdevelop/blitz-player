import SwiftUI

struct GenresView: View {
  let songs: [Song]
  @ObservedObject var audioPlayer: AudioPlayer
  @Binding var selectedSong: Song?
  @State private var grouped: [String: [Song]] = [:]

  var body: some View {
    List {
      ForEach(grouped.keys.sorted(), id: \.self) { genre in
        NavigationLink(
          destination: GenereView(
            songs: grouped[genre] ?? [], genereName: genre, audioPlayer: audioPlayer,
            selectedSong: $selectedSong)
        ) {
          Text(genre)
        }
      }
    }
    .onChange(of: songs) {
      grouped = Dictionary(grouping: songs, by: { $0.genre ?? "Unknown Genre" })
    }
    .onAppear {
      if grouped.isEmpty {
        grouped = Dictionary(grouping: songs, by: { $0.genre ?? "Unknown Genre" })
      }
    }
  }
}
