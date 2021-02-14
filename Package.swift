// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Pulse",
    platforms: [
        .iOS(.v11)
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
            url: "https://github.com/kean/Pulse/files/5976960/PulseCore-0.9.4.zip",
            checksum: "212491123c8ea194af4da73b328d4a5e9d4f00b5a035af3195000d7d4f0eba48"
        ),
        .binaryTarget(
            name: "PulseUI",
            url: "https://github.com/kean/Pulse/files/5976961/PulseUI-0.9.4.zip",
            checksum: "98c0702f7d626bc162019061f1496496314fc0d419204bbb82731d8aecadf75d"
        )
    ]
)
