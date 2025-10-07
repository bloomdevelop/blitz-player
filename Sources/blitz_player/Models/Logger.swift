import Foundation

struct LogEntry: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    let category: String

    enum LogLevel: String, Sendable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

// Global logging function that can be called from any context
func logAsync(_ message: String, level: LogEntry.LogLevel = .info, category: String = "General") {
    Task { @MainActor in
        Logger.shared.log(message, level: level, category: category)
    }
}

@MainActor
class Logger: ObservableObject {
    static let shared = Logger()

    @Published private(set) var logs: [LogEntry] = []
    private let maxLogs = 1000 // Keep only the last 1000 logs

    private init() {}

    func log(_ message: String, level: LogEntry.LogLevel = .info, category: String = "General") {
        let entry = LogEntry(timestamp: Date(), level: level, message: message, category: category)

        logs.append(entry)

        // Keep only the last maxLogs entries
        if logs.count > maxLogs {
            logs.removeFirst(logs.count - maxLogs)
        }
    }

    func debug(_ message: String, category: String = "General") {
        log(message, level: .debug, category: category)
    }

    func info(_ message: String, category: String = "General") {
        log(message, level: .info, category: category)
    }

    func warning(_ message: String, category: String = "General") {
        log(message, level: .warning, category: category)
    }

    func error(_ message: String, category: String = "General") {
        log(message, level: .error, category: category)
    }

    func clear() {
        logs.removeAll()
    }

    func getLogs(for category: String? = nil, level: LogEntry.LogLevel? = nil) -> [LogEntry] {
        return logs.filter { entry in
            if let category = category, entry.category != category { return false }
            if let level = level, entry.level != level { return false }
            return true
        }
    }
}