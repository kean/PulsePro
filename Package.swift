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
            url: "https://github.com/kean/Pulse/files/6058321/PulseCore-0.9.6.zip",
            checksum: "ca730450003caab2fa34b2771a9dadc830b61e6c0b3cda127d42d4ba9ca5b3a1"
        ),
        .binaryTarget(
            name: "PulseUI",
            url: "https://github.com/kean/Pulse/files/6058322/PulseUI-0.9.6.zip",
            checksum: "36de26604aaa4cc4c4ef3d40c21d497449e03e470e1653115aac8a3df1828842"
        )
    ]
)
