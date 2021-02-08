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
            url: "https://github.com/kean/Pulse/files/5947448/PulseUI-9.0.0.zip",
            checksum: "9d4e5e2bbb9a24f99200f6c8c89cdf770e06617ab6fd3c28a69e60b6ff8a3f13"
        ),
        .target(name: "BinaryDependencyWorkaround", dependencies: ["PulseUI", "Pulse"])
    ]
)
