// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Board",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Board",
            targets: ["Board"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Board",
            dependencies: []
        ),
        .testTarget(
            name: "BoardTests",
            dependencies: ["Board"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
