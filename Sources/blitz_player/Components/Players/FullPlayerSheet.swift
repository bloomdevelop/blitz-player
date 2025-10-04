import SwiftUI

struct FullPlayerSheet: View {
    @ObservedObject var audioPlayer: AudioPlayer

    var song: Song?
    var navNamespace: Namespace.ID

    var body: some View {
        ZStack(alignment: .top) {
            if let artwork = song?.artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 50)
                    .overlay(Color.black.opacity(0.4))
                    .ignoresSafeArea()
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                if let song = song {
                    Spacer()

                    // MARK: Album Art
                    if let artwork = song.artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 320, height: 320)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                            .matchedGeometryEffect(id: "albumArt", in: navNamespace)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.gray.opacity(0.3))
                            .frame(width: 320, height: 320)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white.opacity(0.6))
                            )
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                            .matchedGeometryEffect(id: "albumArt", in: navNamespace)
                    }

                    Spacer()

                    // MARK: Song Info
                    VStack(spacing: 8) {
                        Text(song.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Text(song.artist ?? "Unknown Artist")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 24)

                    VStack {
                        CustomSlider(
                            value: Binding(
                                get: {
                                    let d = max(audioPlayer.duration, 0.0001)
                                    let ratio = audioPlayer.currentTime / d
                                    return CGFloat(min(max(ratio, 0), 1))
                                },
                                set: { newVal in
                                    let clamped = min(max(newVal, 0), 1)
                                    let target = audioPlayer.duration * clamped
                                    audioPlayer.seek(to: target)
                                }
                            ),
                            currentTime: formatTime(audioPlayer.currentTime),
                            totalDuration: "-"
                                + formatTime(audioPlayer.duration - audioPlayer.currentTime)
                        )
                        .frame(maxWidth: 320)
                        .frame(height: 6)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 32)

                    // MARK: Playback Controls
                    HStack(spacing: 60) {
                        Button(action: {
                            // TODO)) Implement Next/Prev
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .disabled(true)
                        .opacity(0.5)

                        ReplacableIconButton( prevIcon: "play.fill", nextIcon: "pause.fill", isSwitched: $audioPlayer.isPlaying, action: {
                            audioPlayer.togglePlayback()
                        }, size: 72, color: .white.opacity(0.9))

                        Button(action: {
                            // TODO)) Implement Next/Prev
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .disabled(true)
                        .opacity(0.5)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
