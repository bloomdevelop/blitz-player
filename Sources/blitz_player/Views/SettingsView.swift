import SwiftUI

struct SettingsView: View {
    @ObservedObject var songManager: SongManager
    @State private var showFolderPicker: Bool = false

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
                        songManager.resetDatabase()
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
