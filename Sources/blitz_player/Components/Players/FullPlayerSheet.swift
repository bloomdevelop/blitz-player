import SwiftUI

struct FullPlayerSheet: View {
   @ObservedObject var audioPlayer: AudioPlayer
   @ObservedObject var songManager: SongManager
   @Binding var selectedSong: Song?
   @State private var sliderValue: CGFloat = 0
   @State private var isDragging = false

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
            ArtworkImage(artwork: artwork, size: 320, cornerRadius: 16)
              .frame(width: 320, height: 320)
              .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
          } else {
            // Use ArtworkImage with the song URL as a fallback source (AsyncImage will handle loading/placeholders)
            ArtworkImage(url: song.url, size: 320, cornerRadius: 16)
              .frame(width: 320, height: 320)
              .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
              .clipShape(RoundedRectangle(cornerRadius: 16))
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
            let currentTimeDisplay = isDragging ? audioPlayer.duration * sliderValue : audioPlayer.currentTime
            let remainingTimeDisplay = audioPlayer.duration - currentTimeDisplay
            CustomSlider(
              value: $sliderValue,
              currentTime: formatTime(currentTimeDisplay),
              totalDuration: "-"
                + formatTime(remainingTimeDisplay),
              onEditingChanged: { editing in
                isDragging = editing
                if !editing {
                  let target = audioPlayer.duration * sliderValue
                  audioPlayer.seek(to: target)
                }
              }
            )
            .frame(maxWidth: 320)
            .frame(height: 6)
          }
          .padding(.vertical, 24)
          .padding(.horizontal, 32)

          // MARK: Playback Controls
          HStack(spacing: 60) {
            Button(action: {
              audioPlayer.playPrevious()
            }) {
              Image(systemName: "backward.fill")
                .font(.title)
                .foregroundColor(.white.opacity(0.9))
            }
            .disabled(songManager.songs.count <= 1)
            .opacity(songManager.songs.count <= 1 ? 0.5 : 1)

            ReplacableIconButton(
              prevIcon: "play.fill", nextIcon: "pause.fill", isSwitched: $audioPlayer.isPlaying,
              action: {
                audioPlayer.togglePlayback()
              }, size: 72, color: .white.opacity(0.9))

            Button(action: {
              audioPlayer.playNext()
            }) {
              Image(systemName: "forward.fill")
                .font(.title)
                .foregroundColor(.white.opacity(0.9))
            }
            .disabled(songManager.songs.count <= 1)
            .opacity(songManager.songs.count <= 1 ? 0.5 : 1)
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
    .onAppear {
      updateSliderValue()
    }
    .onChange(of: audioPlayer.currentTime) { _ in
      if !isDragging {
        updateSliderValue()
      }
    }
    .onChange(of: audioPlayer.duration) { _ in
      if !isDragging {
        updateSliderValue()
      }
    }
  }

  func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }

  private func updateSliderValue() {
    let d = max(audioPlayer.duration, 0.0001)
    let ratio = audioPlayer.currentTime / d
    sliderValue = CGFloat(min(max(ratio, 0), 1))
  }
}