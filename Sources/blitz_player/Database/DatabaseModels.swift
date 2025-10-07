@preconcurrency import Foundation
import GRDB
import SQLiteData
import os.log
import UIKit

// MARK: - Database Models

@Table
struct Artist {
    var id: Int64
    var name: String
}

@Table
struct Album {
    var id: Int64
    var name: String
    var artistId: Int64?
}

@Table
struct Genre {
    var id: Int64
    var name: String
}

@Table
struct DBSong {
    var id: Int64
    var title: String?
    var artistId: Int64?
    var albumId: Int64?
    var genreId: Int64?
    var duration: TimeInterval?
    var trackNumber: Int?
    var releaseYear: Int?
    var filePath: String
    var fileURLBookmark: Data?
    var artworkData: Data?

    // Convert from Song struct to DBSong
    init(from song: Song, bookmark: Data?) {
        self.id = 0 // Will be set by database
        self.title = song.title
        self.duration = song.duration
        self.trackNumber = song.trackNumber
        self.releaseYear = song.releaseYear
        self.filePath = song.url.path
        self.fileURLBookmark = bookmark
        // Convert artwork to PNG data for storage
        if let artwork = song.artwork {
            self.artworkData = artwork.pngData()
        } else {
            self.artworkData = nil
        }
        // artistId, albumId, genreId will be set when inserting with relationships
        self.artistId = nil
        self.albumId = nil
        self.genreId = nil
    }
}

// MARK: - Database Manager

@MainActor
class DatabaseManager {
    static let shared = DatabaseManager()

    let dbPool: DatabasePool

    private init() {
        let databaseURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("blitz_player.sqlite")

        Logger.shared.info("Initializing database at: \(databaseURL.path)", category: "Database")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try! migrate()
    }

    private func migrate() throws {
        Logger.shared.info("Starting database migration", category: "Database")
        try dbPool.write { db in
            // Check if we need to recreate tables (migrating from GRDB to SQLiteData)
            let tableExists = try db.tableExists("artist")
            if tableExists {
                Logger.shared.info("Existing database found, checking schema compatibility", category: "Database")
                // Check if the artist table has the expected structure
                do {
                    let _ = try db.execute(sql: "SELECT id, name FROM artist LIMIT 1")
                } catch {
                    Logger.shared.warning("Artist table schema incompatible, recreating database", category: "Database")
                    // Drop existing tables and recreate
                    try db.execute(sql: "DROP TABLE IF EXISTS song")
                    try db.execute(sql: "DROP TABLE IF EXISTS album")
                    try db.execute(sql: "DROP TABLE IF EXISTS artist")
                    try db.execute(sql: "DROP TABLE IF EXISTS genre")
                }
            }

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS artist (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL UNIQUE
                )
                """)
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS album (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    artistId INTEGER REFERENCES artist(id) ON DELETE SET NULL
                )
                """)
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS genre (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL UNIQUE
                )
                """)
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS song (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    title TEXT,
                    artistId INTEGER REFERENCES artist(id) ON DELETE SET NULL,
                    albumId INTEGER REFERENCES album(id) ON DELETE SET NULL,
                    genreId INTEGER REFERENCES genre(id) ON DELETE SET NULL,
                    duration REAL,
                    trackNumber INTEGER,
                    releaseYear INTEGER,
                    filePath TEXT NOT NULL UNIQUE,
                    fileURLBookmark BLOB,
                    artworkData BLOB
                )
                """)
            // Add artworkData column to existing tables if it doesn't exist
            do {
                try db.execute(sql: "ALTER TABLE song ADD COLUMN artworkData BLOB")
            } catch {
                // Column might already exist, ignore error
            }
            // Create indexes for better query performance
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS song_artist_idx ON song(artistId)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS song_album_idx ON song(albumId)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS song_genre_idx ON song(genreId)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS song_title_idx ON song(title)")
        }
        Logger.shared.info("Database migration completed successfully", category: "Database")
    }
    // Resolve bookmark off the main actor to avoid UI blocking
    private static func resolveBookmarkAsync(_ bookmarkData: Data) async throws -> URL {
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

    // MARK: - CRUD Operations

    func insertSong(_ song: Song, bookmark: Data?) throws {
        Logger.shared.info("Inserting song: \(song.title ?? "Unknown") by \(song.artist ?? "Unknown Artist")", category: "Database")
        try dbPool.write { db in
            // Insert or find artist
            var artistId: Int64?
            if let artistName = song.artist {
                try db.execute(sql: "INSERT OR IGNORE INTO artist (name) VALUES (?)", arguments: [artistName])
                artistId = try Int64.fetchOne(db, sql: "SELECT id FROM artist WHERE name = ?", arguments: [artistName])
                Logger.shared.debug("Artist '\(artistName)' ID: \(artistId ?? -1)", category: "Database")
            }

            // Insert or find album
            var albumId: Int64?
            if let albumName = song.album {
                try db.execute(sql: "INSERT OR IGNORE INTO album (name, artistId) VALUES (?, ?)", arguments: [albumName, artistId])
                albumId = try Int64.fetchOne(db, sql: "SELECT id FROM album WHERE name = ? AND (artistId IS ? OR (artistId IS NULL AND ? IS NULL))", arguments: [albumName, artistId, artistId])
                Logger.shared.debug("Album '\(albumName)' ID: \(albumId ?? -1)", category: "Database")
            }

            // Insert or find genre
            var genreId: Int64?
            if let genreName = song.genre {
                try db.execute(sql: "INSERT OR IGNORE INTO genre (name) VALUES (?)", arguments: [genreName])
                genreId = try Int64.fetchOne(db, sql: "SELECT id FROM genre WHERE name = ?", arguments: [genreName])
                Logger.shared.debug("Genre '\(genreName)' ID: \(genreId ?? -1)", category: "Database")
            }

            // Insert song
            var dbSong = DBSong(from: song, bookmark: bookmark)
            dbSong.artistId = artistId
            dbSong.albumId = albumId
            dbSong.genreId = genreId
            try db.execute(sql: """
                INSERT INTO song (title, artistId, albumId, genreId, duration, trackNumber, releaseYear, filePath, fileURLBookmark, artworkData)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, arguments: [
                    dbSong.title, dbSong.artistId, dbSong.albumId, dbSong.genreId,
                    dbSong.duration, dbSong.trackNumber, dbSong.releaseYear,
                    dbSong.filePath, dbSong.fileURLBookmark, dbSong.artworkData
                ])
        }
        Logger.shared.info("Successfully inserted song: \(song.title ?? "Unknown")", category: "Database")
    }

    func fetchAllSongs() throws -> [DBSong] {
        try dbPool.read { db in
            try #sql("SELECT * FROM song", as: DBSong.self).fetchAll(db)
        }
    }

    func fetchSongsWithMetadata() throws -> [Song] {
        let songData = try dbPool.read { db in
            try #sql("""
                SELECT song.*, artist.name as artistName, album.name as albumName, genre.name as genreName
                FROM song
                LEFT JOIN artist ON song.artistId = artist.id
                LEFT JOIN album ON song.albumId = album.id
                LEFT JOIN genre ON song.genreId = genre.id
                """, as: (DBSong, String?, String?, String?).self).fetchAll(db)
        }

        return songData.map { (dbSong, artistName, albumName, genreName) in
            let url = URL(fileURLWithPath: dbSong.filePath)
            var song = Song(url: url)
            song.title = dbSong.title
            song.artist = artistName
            song.album = albumName
            song.genre = genreName
            song.duration = dbSong.duration
            song.trackNumber = dbSong.trackNumber
            song.releaseYear = dbSong.releaseYear
            // Restore artwork from stored data
            if let artworkData = dbSong.artworkData {
                song.artwork = UIImage(data: artworkData)
            }
            return song
        }
    }

    func searchSongs(query: String) throws -> [Song] {
        let pattern = "%\(query)%"
        let songData = try dbPool.read { db in
            try #sql("""
                SELECT song.*, artist.name as artistName, album.name as albumName, genre.name as genreName
                FROM song
                LEFT JOIN artist ON song.artistId = artist.id
                LEFT JOIN album ON song.albumId = album.id
                LEFT JOIN genre ON song.genreId = genre.id
                WHERE song.title LIKE \(raw: pattern) OR song.filePath LIKE \(raw: pattern)
                """, as: (DBSong, String?, String?, String?).self).fetchAll(db)
        }

        return songData.map { (dbSong, artistName, albumName, genreName) in
            var song = Song(url: URL(fileURLWithPath: dbSong.filePath))
            song.title = dbSong.title
            song.artist = artistName
            song.album = albumName
            song.genre = genreName
            song.duration = dbSong.duration
            song.trackNumber = dbSong.trackNumber
            song.releaseYear = dbSong.releaseYear
            // Restore artwork from stored data
            if let artworkData = dbSong.artworkData {
                song.artwork = UIImage(data: artworkData)
            }
            return song
        }
    }

    func clearAllSongs() throws {
        try dbPool.write { db in
            try #sql("DELETE FROM song").execute(db)
            try #sql("DELETE FROM album").execute(db)
            try #sql("DELETE FROM artist").execute(db)
            try #sql("DELETE FROM genre").execute(db)
        }
    }
}