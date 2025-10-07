import SwiftUI
import os.log

@main
struct blitz_playerApp: App {
    init() {
        Logger.shared.info("Blitz Player app starting", category: "App")
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
