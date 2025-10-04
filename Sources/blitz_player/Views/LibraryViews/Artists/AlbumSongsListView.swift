import SwiftUI

struct AlbumSongsListView: View {
    let songs: [Song]
    let albumName: String
    let albumArtwork: UIImage?
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var selectedSong: Song?
    private let albumArtworkSize: CGFloat = 120

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
            if let artwork = albumArtwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: albumArtworkSize, height: albumArtworkSize)
                    .cornerRadius(4)
                    .cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.3))
                    .frame(width: albumArtworkSize, height: albumArtworkSize)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            }

            Text(albumName)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 8)

            List(sortedSongs) { song in
                HStack {
                    if song.trackNumber != nil {
                        Text("\(song.trackNumber!)")
                            .font(.subheadline)
                            .frame(width: 30, alignment: .leading)
                    }

                    VStack(alignment: .leading) {
                        Text(song.name)
                            .font(.headline)
                    }

                    Spacer()

                    if let duration = song.formattedDuration {
                        Text(duration)
                            .font(.subheadline)
                    }
                }
                .onTapGesture {
                    selectedSong = song
                    audioPlayer.startPlayback(url: song.url)
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .scrollContentBackground(.hidden)
    }
}
