import SwiftUI

struct MiniPlayerComponent: View {

    @ObservedObject var audioPlayer: AudioPlayer
    var song: Song?
    var navNamespace: Namespace.ID

    var body: some View {
        if let song = song {
            HStack {
                if let artwork = song.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .cornerRadius(6)
                        .matchedGeometryEffect(id: "albumArt", in: navNamespace)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.gray)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "music.note")
                                .tint(.accentColor)
                                .opacity(0.5)
                        )
                        .matchedGeometryEffect(id: "albumArt", in: navNamespace)
                }

                VStack(alignment: .leading) {
                    Text(song.name)
                        .lineLimit(1)
                        .font(.subheadline)
                    Text("Now Playing")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                ReplacableIconButton(
                    prevIcon: "play.fill",
                    nextIcon: "pause.fill",
                    isSwitched: $audioPlayer.isPlaying,
                    action: {
                        audioPlayer.togglePlayback()
                    },
                    size: 34,
                    color: .primary
                )

                IconButton(
                    icon: "forward.fill",
                    action: {
                        // TODO)) Next/prev track
                    },
                    size: 34,
                    color: .primary
                )
            }
            .padding(10)
            .background(.bar)
            .shadow(radius: 4)
            .cornerRadius(12)
            .padding(.horizontal)
        } else {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.gray)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "music.note")
                            .tint(.accentColor)
                            .opacity(0.5)
                    )

                VStack(alignment: .leading) {
                    Text("No Song Selected")
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Choose a track to play")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                IconButton(
                    icon: "play.fill",
                    action: {},
                    size: 34,
                    color: .primary
                )

                IconButton(
                    icon: "forward.fill",
                    action: {},
                    size: 34,
                    color: .primary
                )
            }
            .padding(10)
            .background(.bar)
            .shadow(radius: 4)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}
