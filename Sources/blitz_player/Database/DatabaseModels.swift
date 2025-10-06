@preconcurrency import Foundation
import GRDB

// MARK: - Database Models

struct Artist: Codable, FetchableRecord, PersistableRecord {
    var databaseId: Int64?
    var name: String

    enum Columns {
        static let databaseId = Column(CodingKeys.databaseId)
        static let name = Column(CodingKeys.name)
    }

    init(databaseId: Int64? = nil, name: String) {
        self.databaseId = databaseId
        self.name = name
    }
}

struct Album: Codable, FetchableRecord, PersistableRecord {
    var databaseId: Int64?
    var name: String
    var artistId: Int64?

    enum Columns {
        static let databaseId = Column(CodingKeys.databaseId)
        static let name = Column(CodingKeys.name)
        static let artistId = Column(CodingKeys.artistId)
    }

    init(databaseId: Int64? = nil, name: String, artistId: Int64? = nil) {
        self.databaseId = databaseId
        self.name = name
        self.artistId = artistId
    }
}

struct Genre: Codable, FetchableRecord, PersistableRecord {
    var databaseId: Int64?
    var name: String

    enum Columns {
        static let databaseId = Column(CodingKeys.databaseId)
        static let name = Column(CodingKeys.name)
    }

    init(databaseId: Int64? = nil, name: String) {
        self.databaseId = databaseId
        self.name = name
    }
}

struct DBSong: Codable, FetchableRecord, PersistableRecord {
    var databaseId: Int64?
    var title: String?
    var artistId: Int64?
    var albumId: Int64?
    var genreId: Int64?
    var duration: TimeInterval?
    var trackNumber: Int?
    var releaseYear: Int?
    var filePath: String
    var fileURLBookmark: Data?

    enum Columns {
        static let databaseId = Column(CodingKeys.databaseId)
        static let title = Column(CodingKeys.title)
        static let artistId = Column(CodingKeys.artistId)
        static let albumId = Column(CodingKeys.albumId)
        static let genreId = Column(CodingKeys.genreId)
        static let duration = Column(CodingKeys.duration)
        static let trackNumber = Column(CodingKeys.trackNumber)
        static let releaseYear = Column(CodingKeys.releaseYear)
        static let filePath = Column(CodingKeys.filePath)
        static let fileURLBookmark = Column(CodingKeys.fileURLBookmark)
    }

    init(databaseId: Int64? = nil, title: String?, artistId: Int64?, albumId: Int64?, genreId: Int64?, duration: TimeInterval?, trackNumber: Int?, releaseYear: Int?, filePath: String, fileURLBookmark: Data?) {
        self.databaseId = databaseId
        self.title = title
        self.artistId = artistId
        self.albumId = albumId
        self.genreId = genreId
        self.duration = duration
        self.trackNumber = trackNumber
        self.releaseYear = releaseYear
        self.filePath = filePath
        self.fileURLBookmark = fileURLBookmark
    }

    // Convert from Song struct to DBSong
    init(from song: Song, bookmark: Data?) {
        self.databaseId = nil
        self.title = song.title
        self.duration = song.duration
        self.trackNumber = song.trackNumber
        self.releaseYear = song.releaseYear
        self.filePath = song.url.path
        self.fileURLBookmark = bookmark
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

    let dbQueue: DatabaseQueue

    private init() {
        let databaseURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("blitz_player.sqlite")

        dbQueue = try! DatabaseQueue(path: databaseURL.path)

        try! migrator.migrate(dbQueue)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "artist") { t in
                t.autoIncrementedPrimaryKey("databaseId")
                t.column("name", .text).notNull().unique()
            }

            try db.create(table: "album") { t in
                t.autoIncrementedPrimaryKey("databaseId")
                t.column("name", .text).notNull()
                t.column("artistId", .integer).references("artist", onDelete: .setNull)
            }

            try db.create(table: "genre") { t in
                t.autoIncrementedPrimaryKey("databaseId")
                t.column("name", .text).notNull().unique()
            }

            try db.create(table: "song") { t in
                t.autoIncrementedPrimaryKey("databaseId")
                t.column("title", .text)
                t.column("artistId", .integer).references("artist", onDelete: .setNull)
                t.column("albumId", .integer).references("album", onDelete: .setNull)
                t.column("genreId", .integer).references("genre", onDelete: .setNull)
                t.column("duration", .double)
                t.column("trackNumber", .integer)
                t.column("releaseYear", .integer)
                t.column("filePath", .text).notNull().unique()
                t.column("fileURLBookmark", .blob)
            }

            // Create indexes for better query performance
            try db.create(index: "song_artist_idx", on: "song", columns: ["artistId"])
            try db.create(index: "song_album_idx", on: "song", columns: ["albumId"])
            try db.create(index: "song_genre_idx", on: "song", columns: ["genreId"])
            try db.create(index: "song_title_idx", on: "song", columns: ["title"])
        }

        return migrator
    }

    // MARK: - CRUD Operations

    func insertSong(_ song: Song, bookmark: Data?) throws {
        try dbQueue.write { db in
            // Insert or find artist
            var artistId: Int64?
            if let artistName = song.artist {
                let existingArtist = try Artist.filter(Artist.Columns.name == artistName).fetchOne(db)
                if let existing = existingArtist {
                    artistId = existing.databaseId
                } else {
                    let newArtist = Artist(name: artistName)
                    if let inserted = try newArtist.insertAndFetch(db, onConflict: .ignore) {
                        artistId = inserted.databaseId
                    }
                }
            }

            // Insert or find album
            var albumId: Int64?
            if let albumName = song.album {
                let existingAlbum = try Album.filter(Album.Columns.name == albumName && Album.Columns.artistId == artistId).fetchOne(db)
                if let existing = existingAlbum {
                    albumId = existing.databaseId
                } else {
                    let newAlbum = Album(name: albumName, artistId: artistId)
                    if let inserted = try newAlbum.insertAndFetch(db, onConflict: .ignore) {
                        albumId = inserted.databaseId
                    }
                }
            }

            // Insert or find genre
            var genreId: Int64?
            if let genreName = song.genre {
                let existingGenre = try Genre.filter(Genre.Columns.name == genreName).fetchOne(db)
                if let existing = existingGenre {
                    genreId = existing.databaseId
                } else {
                    let newGenre = Genre(name: genreName)
                    if let inserted = try newGenre.insertAndFetch(db, onConflict: .ignore) {
                        genreId = inserted.databaseId
                    }
                }
            }

            // Insert song
            var dbSong = DBSong(from: song, bookmark: bookmark)
            dbSong.artistId = artistId
            dbSong.albumId = albumId
            dbSong.genreId = genreId
            try dbSong.insert(db)
        }
    }

    func fetchAllSongs() throws -> [DBSong] {
        try dbQueue.read { db in
            try DBSong.fetchAll(db)
        }
    }

    func fetchSongsWithMetadata() throws -> [Song] {
        try dbQueue.read { db in
            let dbSongs = try DBSong.fetchAll(db)

            let artistIds = Set(dbSongs.compactMap { $0.artistId })
            let artists = artistIds.isEmpty ? [] : try Artist.filter(keys: artistIds).fetchAll(db)
            let artistDict = Dictionary(uniqueKeysWithValues: artists.compactMap { artist in
                artist.databaseId.map { ($0, artist.name) }
            })

            let albumIds = Set(dbSongs.compactMap { $0.albumId })
            let albums = albumIds.isEmpty ? [] : try Album.filter(keys: albumIds).fetchAll(db)
            let albumDict = Dictionary(uniqueKeysWithValues: albums.compactMap { album in
                album.databaseId.map { ($0, album.name) }
            })

            let genreIds = Set(dbSongs.compactMap { $0.genreId })
            let genres = genreIds.isEmpty ? [] : try Genre.filter(keys: genreIds).fetchAll(db)
            let genreDict = Dictionary(uniqueKeysWithValues: genres.compactMap { genre in
                genre.databaseId.map { ($0, genre.name) }
            })

            return dbSongs.map { dbSong in
                var song = Song(url: URL(fileURLWithPath: dbSong.filePath))
                song.title = dbSong.title
                song.artist = dbSong.artistId.flatMap { artistDict[$0] }
                song.album = dbSong.albumId.flatMap { albumDict[$0] }
                song.genre = dbSong.genreId.flatMap { genreDict[$0] }
                song.duration = dbSong.duration
                song.trackNumber = dbSong.trackNumber
                song.releaseYear = dbSong.releaseYear
                return song
            }
        }
    }

    func searchSongs(query: String) throws -> [Song] {
        try dbQueue.read { db in
            let pattern = "%\(query)%"
            let dbSongs = try DBSong.filter(DBSong.Columns.title.like(pattern) ||
                                           DBSong.Columns.filePath.like(pattern)).fetchAll(db)

            let artistIds = Set(dbSongs.compactMap { $0.artistId })
            let artists = artistIds.isEmpty ? [] : try Artist.filter(keys: artistIds).fetchAll(db)
            let artistDict = Dictionary(uniqueKeysWithValues: artists.compactMap { artist in
                artist.databaseId.map { ($0, artist.name) }
            })

            let albumIds = Set(dbSongs.compactMap { $0.albumId })
            let albums = albumIds.isEmpty ? [] : try Album.filter(keys: albumIds).fetchAll(db)
            let albumDict = Dictionary(uniqueKeysWithValues: albums.compactMap { album in
                album.databaseId.map { ($0, album.name) }
            })

            let genreIds = Set(dbSongs.compactMap { $0.genreId })
            let genres = genreIds.isEmpty ? [] : try Genre.filter(keys: genreIds).fetchAll(db)
            let genreDict = Dictionary(uniqueKeysWithValues: genres.compactMap { genre in
                genre.databaseId.map { ($0, genre.name) }
            })

            return dbSongs.map { dbSong in
                var song = Song(url: URL(fileURLWithPath: dbSong.filePath))
                song.title = dbSong.title
                song.artist = dbSong.artistId.flatMap { artistDict[$0] }
                song.album = dbSong.albumId.flatMap { albumDict[$0] }
                song.genre = dbSong.genreId.flatMap { genreDict[$0] }
                song.duration = dbSong.duration
                song.trackNumber = dbSong.trackNumber
                song.releaseYear = dbSong.releaseYear
                return song
            }
        }
    }

    func clearAllSongs() throws {
        try dbQueue.write { db in
            try DBSong.deleteAll(db)
            try Album.deleteAll(db)
            try Artist.deleteAll(db)
            try Genre.deleteAll(db)
        }
    }
}