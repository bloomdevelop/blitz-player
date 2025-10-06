import SwiftUI
import UniformTypeIdentifiers

struct FolderPickerWrapper: UIViewControllerRepresentable {
  var onPick: (URL) -> Void

  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.allowsMultipleSelection = false
    picker.delegate = context.coordinator
    return picker
  }

  // Currently it does nothing.
  func updateUIViewController(
    _ uiViewController: UIDocumentPickerViewController, context: Context
  ) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(onPick: onPick)
  }

  class Coordinator: NSObject, UIDocumentPickerDelegate {
    var onPick: (URL) -> Void

    init(onPick: @escaping (URL) -> Void) {
      self.onPick = onPick
    }

    func documentPicker(
      _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
    ) {
      guard let url = urls.first else { return }

      // Start security-scoped access
      if url.startAccessingSecurityScopedResource() {
        defer { url.stopAccessingSecurityScopedResource() }

        do {
          // Create a security-scoped bookmark for persistent access
          let bookmark = try url.bookmarkData(includingResourceValuesForKeys: nil, relativeTo: nil)

          // Save both the bookmark and the resolved URL
          UserDefaults.standard.set(bookmark, forKey: "SavedMusicFolderBookmark")
          UserDefaults.standard.set(url.path, forKey: "SavedMusicFolderPath")
          print("[INFO] Saved folder bookmark and path")

          // Notify that a folder was picked
          onPick(url)
        } catch {
          print("[ERROR] Failed to create bookmark: \(error)")
        }
      }
    }
  }
}
