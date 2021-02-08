// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PulseUI",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "PulseUI", targets: ["PulseUI"]),
    ],
    targets: [
        .binaryTarget(
            name: "PulseUI",
            url: "https://github.com/kean/Pulse/files/5947467/PulseUI-0.9.0.zip",
            checksum: "4696e9f408cfb6a684f604c7507bca4c7018de3eb15f1034f8e442d9ecd6c61a"
        )
    ]
)
