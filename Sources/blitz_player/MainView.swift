import SwiftUI

struct MainView: View {
    @Namespace private var navNamespace
    @StateObject private var songManager = SongManager()
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var selectedSong: Song?
    @State private var showingFilePicker = false
    @State private var showFullPlayer = false
    
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
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Open Folder") {
                                showingFilePicker.toggle()
                            }
                            .sheet(isPresented: $showingFilePicker) {
                                FolderPickerWrapper { folder in
                                    print("Picked folder: \(folder)")
                                    songManager.pickFolder(folder)
                                }
                            }
                        }
                    }
                    .navigationTitle("Home")
                }
                .tabItem {
                    Label("Home", systemImage: "house")
                }

                NavigationView {
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

                Text("Settings")
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }

            let currentSelected = selectedSong.flatMap { sel in
                songManager.songs.first(where: { $0.url == sel.url }) ?? sel
            }
            if !showFullPlayer {
                MiniPlayerComponent(
                    audioPlayer: audioPlayer,
                    song: currentSelected,
                    navNamespace: navNamespace
                )
                .padding(.horizontal, 2)
                .padding(.bottom, 60)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showFullPlayer = true
                    }
                }
            }
        }
        .sheet(isPresented: $showFullPlayer) {
            let currentSelected = selectedSong.flatMap { sel in
                songManager.songs.first(where: { $0.url == sel.url }) ?? sel
            }
            FullPlayerSheet(
                audioPlayer: audioPlayer,
                song: currentSelected,
                navNamespace: navNamespace
            )
            .transition(.scale)
            .presentationDragIndicator(.visible)
        }
    }
}
