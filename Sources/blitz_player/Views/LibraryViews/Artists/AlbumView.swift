import SwiftUI

struct AlbumSongsListView: View {
  let songs: [Song]
  let albumName: String
  let albumArtwork: UIImage?
  private let albumArtworkSize: CGFloat = 120
  @ObservedObject var audioPlayer: AudioPlayer
  @ObservedObject var songManager: SongManager
  @Binding var selectedSong: Song?

  var sortedSongs: [Song] {
    songs.sorted { (lhs, rhs) -> Bool in
      if let lhsTrack = lhs.trackNumber, let rhsTrack = rhs.trackNumber {
        return lhsTrack < rhsTrack
      } else if lhs.trackNumber != nil {
        return true
      } else if rhs.trackNumber != nil {
        return false
      } else {
        return lhs.name < rhs.name
      }
    }
  }

  var body: some View {
    VStack {
      ArtworkImage(artwork: albumArtwork, size: albumArtworkSize)

      Text(albumName)
        .font(.title2)
        .fontWeight(.bold)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
        .padding(.top, 8)

      // Play All Button
      Button(action: {
        songManager.clearQueue()
        songManager.appendToQueue(sortedSongs)
        if let firstSong = sortedSongs.first {
          selectedSong = firstSong
          audioPlayer.startPlayback(song: firstSong)
        }
      }) {
        HStack {
          Image(systemName: "play.fill")
          Text("Play All")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(8)
      }
      .padding(.top, 8)

      List(sortedSongs) { song in
        HStack {
          Text(song.name)
          Text(song.formattedDuration ?? "Unknown")
        }
        .swipeActions(edge: .leading) {
          Button(action: {
            selectedSong = song
            audioPlayer.startPlayback(song: song)
          }) {
            Label("Play", systemImage: "play.fill")
          }.tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
          Button(action: {
            songManager.appendToQueue(song)
          }) {
            Label("Append to Queue", systemImage: "text.append")
          }.tint(.green)
          Button(action: {
            // Favorite action - placeholder
          }) {
            Label("Favorite", systemImage: "star.fill")
          }.tint(.yellow)
        }
        .onTapGesture {
          selectedSong = song
          audioPlayer.startPlayback(song: song)
        }
      }
      .listStyle(.plain)
    }
    .scrollContentBackground(.hidden)
  }
}
