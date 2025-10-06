import AVFoundation
import Foundation
import UIKit
import GRDB

// MARK: - Structs
struct SongMetadata {
  var title: String?
  var artist: String?
  var album: String?
  var genre: String?
  var releaseYear: Int?
  var duration: TimeInterval?
  var trackNumber: Int?
  var currentTime: TimeInterval?
  var lyrics: String?
  var producer: String?
  var label: String?
  var artwork: UIImage?
}

struct Song: Identifiable, Codable {
  let id = UUID()
  let url: URL

  // Required metadata fields
  var title: String?
  var artist: String?
  var album: String?
  var genre: String?
  var releaseYear: Int?
  var duration: TimeInterval?
  var trackNumber: Int?

  // Playback state (updated during playback)
  var currentTime: TimeInterval?

  // Optional metadata fields
  var lyrics: String?
  var producer: String?
  var label: String?

  var artwork: UIImage?

  // Computed property for display name, fallback to filename
  var name: String {
    title ?? url.deletingPathExtension().lastPathComponent
  }

  // Computed property for formatted duration (minutes:seconds)
  var formattedDuration: String? {
    guard let duration = duration else { return nil }
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }

  // Computed property for formatted current time
  var formattedCurrentTime: String? {
    guard let currentTime = currentTime else { return nil }
    let minutes = Int(currentTime) / 60
    let seconds = Int(currentTime) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }

  // Computed property for remaining time
  var remainingTime: TimeInterval? {
    guard let duration = duration, let currentTime = currentTime else { return nil }
    return duration - currentTime
  }

  // Computed property for formatted remaining time
  var formattedRemainingTime: String? {
    guard let remainingTime = remainingTime else { return nil }
    let minutes = Int(remainingTime) / 60
    let seconds = Int(remainingTime) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }

  init(url: URL) {
    self.url = url
    self.title = nil
    self.artist = nil
    self.album = nil
    self.genre = nil
    self.releaseYear = nil
    self.duration = nil
    self.trackNumber = nil
    self.currentTime = nil
    self.lyrics = nil
    self.producer = nil
    self.label = nil
    self.artwork = nil
  }

  init(url: URL, metadata: SongMetadata) {
    self.url = url
    self.title = metadata.title
    self.artist = metadata.artist
    self.album = metadata.album
    self.genre = metadata.genre
    self.releaseYear = metadata.releaseYear
    self.duration = metadata.duration
    self.trackNumber = metadata.trackNumber
    self.currentTime = metadata.currentTime
    self.lyrics = metadata.lyrics
    self.producer = metadata.producer
    self.label = metadata.label
    self.artwork = metadata.artwork
  }

  // Custom CodingKeys to exclude non-codable properties
  enum CodingKeys: String, CodingKey {
    case id, url, title, artist, album, genre, releaseYear, duration, trackNumber, currentTime,
      lyrics, producer, label
    // artwork is not codable, so excluded
  }
}

// MARK: - Song Manager Class
@MainActor
class SongManager: ObservableObject {
  @Published var songs: [Song] = []
  private var currentSecurityScopedURL: URL?

  init() {
    // Try to load from database first
    Task {
      await loadSongsFromDatabase()
      if songs.isEmpty {
        print("[DEBUG] Database empty, loading from saved bookmark")
        // If database is empty, try to load from saved bookmark, then fall back to documents directory
        loadSongsFromSavedBookmark()
        if songs.isEmpty {
          print("[DEBUG] No saved bookmark, loading from documents")
          loadSongs()
        }
      } else {
        print("[DEBUG] Loaded \(songs.count) songs from database")
      }
    }
  }

  private func setSecurityScopedFolder(_ url: URL?) {
    // Stop access to the previous folder
    if let currentURL = currentSecurityScopedURL {
      currentURL.stopAccessingSecurityScopedResource()
    }

    // Start access to the new folder
    if let newURL = url, newURL.startAccessingSecurityScopedResource() {
      currentSecurityScopedURL = newURL
    } else {
      currentSecurityScopedURL = nil
    }
  }

  // Resolve bookmark off the main actor to avoid UI blocking
  private nonisolated static func resolveBookmarkAsync(_ bookmarkData: Data) async throws -> URL {
    try await Task.detached(priority: .userInitiated) { () throws -> URL in
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: bookmarkData,
        options: [.withoutUI, .withoutMounting],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      if isStale {
        print("[WARNING] Bookmark is stale, folder may have moved")
      }
      return url
    }.value
  }

  // MARK: - Song Loading
  func loadSongs(from folder: URL) {
    // Set up security-scoped access for the folder
    setSecurityScopedFolder(folder)

    // Supported audio file extensions
    let exts: Set<String> = ["mp3", "flac", "wav", "m4a"]

    Task.detached(priority: .userInitiated) { [weak self] in
      // Recursively enumerate folder contents
      let enumerator = FileManager.default.enumerator(
        at: folder,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
      )

      var audioFiles: [URL] = []
      if let enumerator {
        while let next = enumerator.nextObject() as? URL {
          // Cooperative cancellation
          if Task.isCancelled { break }
          if exts.contains(next.pathExtension.lowercased()) {
            audioFiles.append(next)
          }
        }
      }

      // Stable ordering for UI
      audioFiles.sort {
        $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent)
          == .orderedAscending
      }

      if Task.isCancelled {
        await MainActor.run { [weak self] in
          self?.songs = []
        }
        return
      }

      // Create songs with metadata concurrently, limited to 4 concurrent tasks per chunk
      let chunkSize = 4
      var indexedSongs: [(Int, Song)] = []
      for start in stride(from: 0, to: audioFiles.count, by: chunkSize) {
        let end = min(start + chunkSize, audioFiles.count)
        let chunk = Array(audioFiles[start..<end])
        let chunkResults = await withTaskGroup(of: (Int, Song).self) { group in
          for (localIndex, url) in chunk.enumerated() {
            let globalIndex = start + localIndex
            group.addTask {
              let metadata = await Self.loadMetadata(from: url)
              let song = Song(url: url, metadata: metadata)
              return (globalIndex, song)
            }
          }
          var results: [(Int, Song)] = []
          for await result in group {
            results.append(result)
          }
          return results
        }
        indexedSongs.append(contentsOf: chunkResults)
      }
      let loadedSongs = indexedSongs.sorted { $0.0 < $1.0 }.map { $0.1 }

      // Publish song list on main actor
      await MainActor.run { [weak self] in
        self?.songs = loadedSongs
        // Index songs in database
        self?.indexSongsInDatabase(loadedSongs)
      }
    }
  }

  // MARK: - Metadata loading
  private static func loadMetadata(from url: URL) async -> SongMetadata {
    let asset = AVURLAsset(url: url)
    var metadata = SongMetadata()

    if #available(iOS 16.0, *) {
      do {
        let formats: [AVMetadataFormat] = [
          .id3Metadata, .iTunesMetadata, .quickTimeMetadata,
        ]
        for format in formats {
          let items = try await asset.loadMetadata(for: format)
          for item in items {
            switch item.commonKey {
            case .commonKeyTitle:
              metadata.title = try? await item.load(.stringValue)
            case .commonKeyArtist:
              metadata.artist = try? await item.load(.stringValue)
            case .commonKeyAlbumName:
              metadata.album = try? await item.load(.stringValue)
            case .commonKeyType:
              metadata.genre = try? await item.load(.stringValue)
            case .id3MetadataKeyYear:
              if let yearString = try? await item.load(.stringValue),
                let year = Int(yearString)
              {
                metadata.releaseYear = year
              }
            case .iTunesMetadataKeyTrackNumber:
              if let trackString = try? await item.load(.stringValue),
                let track = Int(trackString)
              {
                metadata.trackNumber = track
              }
            case .iTunesMetadataKeyLyrics:
              metadata.lyrics = try? await item.load(.stringValue)
            case .commonKeyArtwork:
              if let data = try? await item.load(.dataValue),
                let image = UIImage(data: data)
              {
                metadata.artwork = image
              }
            // Note: Producer and Label may require custom identifier keys
            default:
              break
            }
          }
        }
      } catch {
        // Ignore errors and continue with what we have
      }
    } else {
      // Fallback for iOS < 16
      let formats: [AVMetadataFormat] = [.id3Metadata, .iTunesMetadata, .quickTimeMetadata]
      for format in formats {
        let items = asset.metadata(forFormat: format)
        for item in items {
          switch item.commonKey {
          case .commonKeyTitle:
            metadata.title = item.stringValue
          case .commonKeyArtist:
            metadata.artist = item.stringValue
          case .commonKeyAlbumName:
            metadata.album = item.stringValue
          case .commonKeyType:
            metadata.genre = item.stringValue
          case .id3MetadataKeyYear:
            if let yearString = item.stringValue, let year = Int(yearString) {
              metadata.releaseYear = year
            }
          case .iTunesMetadataKeyTrackNumber:
            if let trackString = item.stringValue, let track = Int(trackString) {
              metadata.trackNumber = track
            }
          case .iTunesMetadataKeyLyrics:
            metadata.lyrics = item.stringValue
          case .commonKeyArtwork:
            if let data = item.dataValue,
              let image = UIImage(data: data)
            {
              metadata.artwork = image
            }
          // Note: Producer and Label may require custom identifier keys
          default:
            break
          }
        }
      }
    }

    // Load duration
    do {
      let duration = try await asset.load(.duration)
      metadata.duration = CMTimeGetSeconds(duration)
    } catch {
      // Duration might be available from AudioPlayer later
    }

    return metadata
  }

  // MARK: - Artwork loading
  private static func loadArtwork(from url: URL) async -> UIImage? {
    let asset = AVURLAsset(url: url)
    if #available(iOS 16.0, *) {
      do {
        // Check multiple formats as artwork may be stored differently depending on file/container
        let formats: [AVMetadataFormat] = [
          .id3Metadata, .iTunesMetadata, .quickTimeMetadata,
        ]
        for format in formats {
          let metadata = try await asset.loadMetadata(for: format)
          for item in metadata {
            if item.commonKey == .commonKeyArtwork,
              let data = try await item.load(.dataValue),
              let image = UIImage(data: data)
            {
              return image
            }
          }
        }
      } catch {
        // Ignore and fall back to nil
      }
      return nil
    } else {
      // Fallback for iOS < 16
      let formats: [AVMetadataFormat] = [.id3Metadata, .iTunesMetadata, .quickTimeMetadata]
      for format in formats {
        let metadata = asset.metadata(forFormat: format)
        for item in metadata {
          if item.commonKey == .commonKeyArtwork, let data = item.dataValue,
            let image = UIImage(data: data)
          {
            return image
          }
        }
      }
      return nil
    }
  }

  /// Loads artwork for a specific song asynchronously and updates the song in the list if not already loaded
  @MainActor
  func loadArtwork(for songId: UUID) async {
    // Early return if already loaded
    if let song = songs.first(where: { $0.id == songId }), song.artwork != nil {
      return
    }

    guard let song = songs.first(where: { $0.id == songId }) else { return }

    let artwork = await Self.loadArtwork(from: song.url)

    guard let index = songs.firstIndex(where: { $0.id == songId }) else { return }

    var updatedSong = songs[index]
    updatedSong.artwork = artwork
    songs[index] = updatedSong
  }

  func loadSongsFromDatabase() async {
    do {
      let songs = try DatabaseManager.shared.fetchSongsWithMetadata()
      self.songs = songs
      print("[INFO] Loaded \(songs.count) songs from database")
    } catch {
      print("[ERROR] Failed to load songs from database: \(error)")
    }
  }

  func loadSongsFromSavedBookmark() {
    guard let bookmarkData = UserDefaults.standard.data(forKey: "SavedMusicFolderBookmark")
    else {
      print("[INFO] No saved bookmark found")
      return
    }

    // Launch on main actor and offload the heavy bookmark resolution
    Task { @MainActor in
      do {
        let folderURL = try await Self.resolveBookmarkAsync(bookmarkData)
        self.setSecurityScopedFolder(folderURL)
        self.loadSongs(from: folderURL)
        print("[INFO] Loaded songs from saved bookmark")
      } catch {
        print("[ERROR] Failed to resolve bookmark: \(error)")
        self.setSecurityScopedFolder(nil)
      }
    }
  }

  func loadSongs() {
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    loadSongs(from: docs)
  }

  func pickFolder(_ folder: URL) {
    // Set up security-scoped access for the newly picked folder
    setSecurityScopedFolder(folder)

    // Load songs from the folder
    loadSongs(from: folder)

    // Create and save bookmark for the folder
    do {
      let bookmark = try folder.bookmarkData(
        includingResourceValuesForKeys: nil, relativeTo: nil)
      UserDefaults.standard.set(bookmark, forKey: "SavedMusicFolderBookmark")
      print("[INFO] Saved folder bookmark")
    } catch {
      print("[ERROR] Failed to create bookmark: \(error)")
    }
  }

  private func indexSongsInDatabase(_ songs: [Song]) {
    Task {
      do {
        try DatabaseManager.shared.clearAllSongs()

        for song in songs {
          let bookmark = try? song.url.bookmarkData(
            includingResourceValuesForKeys: nil,
            relativeTo: nil
          )
          try DatabaseManager.shared.insertSong(song, bookmark: bookmark)
        }
        print("[INFO] Indexed \(songs.count) songs in database")
      } catch {
        print("[ERROR] Failed to index songs in database: \(error)")
      }
    }
  }
}