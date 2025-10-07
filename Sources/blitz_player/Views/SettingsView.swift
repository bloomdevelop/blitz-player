import SwiftUI

struct SettingsView: View {
    @ObservedObject var songManager: SongManager
    @ObservedObject var audioPlayer: AudioPlayer
    @State private var showFolderPicker: Bool = false
    @State private var crossfadeDuration: Double = 2.0

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Database")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        if songManager.isIndexing {
                            Text("Indexing...")
                                .foregroundColor(.orange)
                        } else {
                            Text(songManager.songs.isEmpty ? "Not Indexed" : "Indexed")
                                .foregroundColor(songManager.songs.isEmpty ? .red : .green)
                        }
                    }

                    if songManager.isIndexing {
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: songManager.indexingProgress) {
                                Text(songManager.indexingStatus)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .progressViewStyle(.linear)
                        }
                        .padding(.vertical, 4)
                    }

                    HStack {
                        Text("Indexed Songs")
                        Spacer()
                        Text("\(songManager.songs.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Open Folder", systemImage: "plus.circle")
                    }
                    .onTapGesture {
                        showFolderPicker = true
                    }
                }

                Section(header: Text("Playback")) {
                    VStack(alignment: .leading) {
                        Text("Crossfade Duration")
                            .font(.headline)
                        Text("Duration of crossfade between tracks (0 = disabled)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $crossfadeDuration, in: 0...10, step: 0.5) {
                            Text("Crossfade")
                        } minimumValueLabel: {
                            Text("0s")
                        } maximumValueLabel: {
                            Text("10s")
                        }
                        .onChange(of: crossfadeDuration) { oldValue, newValue in
                            audioPlayer.updateCrossfadeDuration(newValue)
                        }
                        Text("\(String(format: "%.1f", crossfadeDuration)) seconds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("Debug")) {
                    NavigationLink(destination: DebugLogsView()) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("Debug Logs")
                        }
                    }
                }

                Section(header: Text("Dangerous Actions")) {
                    HStack {
                        Label("Reset Database", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .onTapGesture {
                        Task { await songManager.resetDatabase() }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showFolderPicker) {
                FolderPickerWrapper { folder in
                    print("Picked folder: \(folder)")
                    songManager.pickFolder(folder)
                }
            }
        }
    }
}
