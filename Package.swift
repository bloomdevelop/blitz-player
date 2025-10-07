// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "blitz-player",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        // An xtool project should contain exactly one library product,
        // representing the main app.
        .library(
            name: "blitz_player",
            targets: ["blitz_player"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/AudioKit/AudioKit", from: "5.6.4"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.8.0"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
        .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "blitz_player",
            dependencies: [
                "AudioKit",
                .product(name: "GRDB", package: "grdb.swift"),
                .product(name: "SQLiteData", package: "sqlite-data")
            ],
        )
    ]
)
