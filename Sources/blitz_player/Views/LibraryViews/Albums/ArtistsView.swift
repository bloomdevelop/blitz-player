import SwiftUI

struct ArtistsView: View {
  let songs: [Song]
  @ObservedObject var audioPlayer: AudioPlayer
  @Binding var selectedSong: Song?
  @State private var grouped: [String: [Song]] = [:]

  var body: some View {
    List {
      ForEach(grouped.keys.sorted(), id: \.self) { artist in
        NavigationLink(
          destination: ArtistSongsListView(
            songs: grouped[artist] ?? [], artistName: artist, audioPlayer: audioPlayer,
            selectedSong: $selectedSong)

        ) {
          Text(artist)
        }
      }
    }
    .onChange(of: songs) {
      grouped = Dictionary(grouping: songs, by: { $0.artist ?? "Unknown Artist" })
    }
    .onAppear {
      if grouped.isEmpty {
        grouped = Dictionary(grouping: songs, by: { $0.artist ?? "Unknown Artist" })
      }
    }
  }
}
