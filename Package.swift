// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Pulse",
    platforms: [
        .iOS(.v11),
        .macOS(.v11),
        .watchOS(.v6)
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
            url: "https://github.com/kean/Pulse/files/6138052/PulseCore-0.10.0.zip",
            checksum: "2761e2d0e3691d1890240cd1ec7e803e83d418ffe959c0bccb178acbc8d01edb"
        ),
        .binaryTarget(
            name: "PulseUI",
            url: "https://github.com/kean/Pulse/files/6138053/PulseUI-0.10.0.zip",
            checksum: "cb8d0100ca31317aabfcb64084abdd1272d4c1d43175261bf3e825de9bee6859"
        )
    ]
)
