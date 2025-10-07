import SwiftUI

struct MainView: View {
  @Namespace private var navNamespace
  @StateObject private var songManager = SongManager()
  @StateObject private var audioPlayer = AudioPlayer()
  @State private var selectedSong: Song?
  @State private var showingFilePicker = false
  @State private var showFullPlayer = false

  init() {
    audioPlayer.songManager = songManager
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      TabView {
        NavigationView {
          ContentView(
            songManager: songManager,
            audioPlayer: audioPlayer,
            selectedSong: $selectedSong
          )
          .navigationTitle("Home")
        }
        .tabItem {
          Label("Home", systemImage: "house")
        }

        NavigationStack {
          LibraryPage(
            songManager: songManager,
            audioPlayer: audioPlayer,
            selectedSong: $selectedSong
          )
          .navigationTitle("Library")
        }
        .tabItem {
          Label("Library", systemImage: "play.square.stack")
        }

        NavigationStack {
          SettingsView(songManager: songManager)
            .navigationTitle("Settings")
        }
        .tabItem {
          Label("Settings", systemImage: "gear")
        }
      }

      let currentSelected = selectedSong.flatMap { sel in
        songManager.songs.first(where: { $0.url == sel.url }) ?? sel
      }
      MiniPlayerComponent(
         audioPlayer: audioPlayer,
         songManager: songManager,
         selectedSong: $selectedSong,
         song: currentSelected,
         navNamespace: navNamespace
       )
      .padding(.horizontal, 2)
      .padding(.bottom, 60)
      .onTapGesture {
        if currentSelected != nil {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            showFullPlayer = true
          }
        }
      }
      .onChange(of: audioPlayer.currentSong) { oldValue, newValue in selectedSong = newValue }
    }
    .environmentObject(songManager)
    .sheet(isPresented: $showFullPlayer) {
      let currentSelected = selectedSong.flatMap { sel in
        songManager.songs.first(where: { $0.url == sel.url }) ?? sel
      }
      FullPlayerSheet(
        audioPlayer: audioPlayer,
        songManager: songManager,
        selectedSong: $selectedSong,
        song: currentSelected,
        navNamespace: navNamespace
      )
      .transition(.scale)
      .presentationDragIndicator(.visible)
    }
  }
}
