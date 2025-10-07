import SwiftUI

struct DebugLogsView: View {
    @ObservedObject var logger = Logger.shared
    @State private var selectedLevel: LogEntry.LogLevel? = nil
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""

    var filteredLogs: [LogEntry] {
        var logs = logger.logs

        if let level = selectedLevel {
            logs = logs.filter { $0.level == level }
        }

        if let category = selectedCategory {
            logs = logs.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            logs = logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }

        return logs.reversed() // Show newest first
    }

    var availableCategories: [String] {
        Array(Set(logger.logs.map { $0.category })).sorted()
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Filters
                HStack {
                    Picker("Level", selection: $selectedLevel) {
                        Text("All").tag(LogEntry.LogLevel?.none)
                        Text("DEBUG").tag(LogEntry.LogLevel?.some(.debug))
                        Text("INFO").tag(LogEntry.LogLevel?.some(.info))
                        Text("WARNING").tag(LogEntry.LogLevel?.some(.warning))
                        Text("ERROR").tag(LogEntry.LogLevel?.some(.error))
                    }
                    .pickerStyle(.menu)

                    Picker("Category", selection: $selectedCategory) {
                        Text("All").tag(String?.none)
                        ForEach(availableCategories, id: \.self) { category in
                            Text(category).tag(String?.some(category))
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer()

                    Button(action: {
                        logger.clear()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)

                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                // Logs list
                List(filteredLogs) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.formattedTimestamp)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(entry.level.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(levelColor(for: entry.level))
                                .foregroundColor(.white)
                                .cornerRadius(4)

                            Text(entry.category)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        Text(entry.message)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func levelColor(for level: LogEntry.LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}