import SwiftUI

struct FullPlayerSheet: View {
   @ObservedObject var audioPlayer: AudioPlayer
   @ObservedObject var songManager: SongManager
   @Binding var selectedSong: Song?
   @State private var sliderValue: CGFloat = 0
   @State private var isDragging = false
   @State private var showQueue = false

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
          let hasArtwork = song.artwork != nil
          let textColor: Color = hasArtwork ? .white : .primary
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
              .foregroundColor(textColor)
              .lineLimit(2)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)

            Text(song.artist ?? "Unknown Artist")
              .font(.body)
              .foregroundColor(textColor.opacity(0.7))
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
                .foregroundColor(textColor.opacity(0.9))
            }
            .disabled((songManager.queue.isEmpty ? songManager.songs.count : songManager.queue.count) <= 1)
            .opacity((songManager.queue.isEmpty ? songManager.songs.count : songManager.queue.count) <= 1 ? 0.5 : 1)

            ReplacableIconButton(
              prevIcon: "play.fill", nextIcon: "pause.fill", isSwitched: $audioPlayer.isPlaying,
              action: {
                audioPlayer.togglePlayback()
              }, size: 72, color: textColor.opacity(0.9))

            Button(action: {
              audioPlayer.playNext()
            }) {
              Image(systemName: "forward.fill")
                .font(.title)
                .foregroundColor(textColor.opacity(0.9))
            }
            .disabled((songManager.queue.isEmpty ? songManager.songs.count : songManager.queue.count) <= 1)
            .opacity((songManager.queue.isEmpty ? songManager.songs.count : songManager.queue.count) <= 1 ? 0.5 : 1)
          }
          .padding(.horizontal, 32)
          .padding(.top, 24)
          .padding(.bottom, 40)

          // Queue Toggle Button
          Button(action: {
            withAnimation {
              showQueue.toggle()
            }
          }) {
            HStack {
              Image(systemName: "list.bullet")
              Text("Queue (\(songManager.queue.count))")
            }
            .foregroundColor(textColor.opacity(0.9))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
          }
          .padding(.horizontal, 32)
          .padding(.bottom, 20)

          // Queue List
          if showQueue && !songManager.queue.isEmpty {
            List {
              ForEach(songManager.queue.indices, id: \.self) { index in
                let song = songManager.queue[index]
                HStack {
                  Text("\(index + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30)
                  VStack(alignment: .leading) {
                    Text(song.name)
                      .foregroundColor(song.id == audioPlayer.currentSong?.id ? .accentColor : textColor)
                    Text(song.artist ?? "Unknown Artist")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  Spacer()
                  Button(action: {
                    songManager.removeFromQueue(at: index)
                  }) {
                    Image(systemName: "xmark")
                      .foregroundColor(.secondary)
                  }
                }
                .swipeActions {
                  Button(role: .destructive) {
                    songManager.removeFromQueue(at: index)
                  } label: {
                    Label("Remove", systemImage: "trash")
                  }
                }
                .onTapGesture {
                  selectedSong = song
                  audioPlayer.startPlayback(song: song)
                }
              }
              .onMove { indices, newOffset in
                songManager.moveQueueItem(from: indices, to: newOffset)
              }
            }
            .listStyle(.plain)
            .frame(height: 300)
            .background(Color.black.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
          }
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
    .onChange(of: audioPlayer.currentTime) {
      if !isDragging {
        updateSliderValue()
      }
    }
    .onChange(of: audioPlayer.duration) {
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