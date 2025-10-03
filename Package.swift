// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "blitz-player",
    platforms: [
        .iOS(.v18),
    ],
    products: [
        // An xtool project should contain exactly one library product,
        // representing the main app.
        .library(
            name: "blitz_player",
            targets: ["blitz_player"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/AudioKit/AudioKit", from: "5.6.4"),
    ],
    targets: [
        .target(
            name: "blitz_player",
            dependencies: ["AudioKit"],
        ),
    ]
)
