// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PulseUI",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "PulseUI", targets: ["Pulse", "PulseCore", "PulseUI"])
    ],
    targets: [
        .binaryTarget(
            name: "Pulse",
            url: "https://github.com/kean/Pulse/files/5951687/Pulse-0.9.0.zip",
            checksum: "cfd1a752af6037e6849be92cbb25ae7ff0d3ee885006a0481f1242a025c16100"
        ),
        .binaryTarget(
            name: "PulseCore",
            url: "https://github.com/kean/Pulse/files/5951688/PulseCore-0.9.0.zip",
            checksum: "5871fb4be51a16e017969f6cb0e4e65852cd8c241f43a5f965233a184576584d"
        ),
        .binaryTarget(
            name: "PulseUI",
            url: "https://github.com/kean/Pulse/files/5951689/PulseUI-0.9.0.zip",
            checksum: "72b9bbf3355e0f306c008277bb5b7d03aa96047c81f6e2d5557994b1c3525faf"
        )
    ]
)
