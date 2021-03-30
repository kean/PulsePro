// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Pulse",
    platforms: [
        .iOS(.v11),
        .macOS(.v11),
        .watchOS(.v6),
        .tvOS(.v11)
    ],
    products: [
        .library(name: "Pulse", targets: ["Pulse"]),
        .library(name: "PulseCore", targets: ["PulseCore"]),
        .library(name: "PulseUI", targets: ["PulseUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "Pulse",
            dependencies: [.product(name: "Logging", package: "swift-log"), "PulseCore"],
            path: "Sources/Pulse"
        ),
        .binaryTarget(
            name: "PulseCore",
            url: "https://github.com/kean/Pulse/files/6225487/PulseCore-0.14.0.zip",
            checksum: "d54637750fefe5f65c4f5376d9e15524c368c595899adf994346cf69b71d55db"
        ),
        .binaryTarget(
            name: "PulseUI",
            url: "https://github.com/kean/Pulse/files/6225488/PulseUI-0.14.0.zip",
            checksum: "77e2a1646a2d6d2e89146d67b10f8e8f18ad5773c48137681ff0d414bfe3fbac"
        )
    ]
)
