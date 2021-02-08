// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PulseUI",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "PulseUI", targets: ["PulseUI", "BinaryDependencyWorkaround"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Pulse.git", from: "0.6.0")
    ],
    targets: [
        .binaryTarget(
            name: "PulseUI",
            url: "https://github.com/kean/Pulse/files/5947467/PulseUI-0.9.0.zip",
            checksum: "4696e9f408cfb6a684f604c7507bca4c7018de3eb15f1034f8e442d9ecd6c61a"
        ),
        .target(name: "BinaryDependencyWorkaround", dependencies: ["PulseUI", "Pulse"])
    ]
)
