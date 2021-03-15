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
            url: "https://github.com/kean/Pulse/files/6138223/PulseCore-0.10.1.zip",
            checksum: "ba2c236719f60c7811318da18b11804e446129320c93516705aae80682518e4c"
        ),
        .binaryTarget(
            name: "PulseUI",
            url: "https://github.com/kean/Pulse/files/6138230/PulseUI-0.10.1.zip",
            checksum: "8da8ea981d4da1daff9ed1296d1c7f80bf37da60923ddfc67c629d4560037809"
        )
    ]
)
