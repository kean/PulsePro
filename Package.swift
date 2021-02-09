// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PulseUI",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "PulseUI", targets: ["PulseUITarget"])
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Pulse.git", .branch("dyn"))
    ],
    targets: [
        .target(
            name: "PulseUITarget",
            dependencies: ["PulseUIWrapper"]
        ),
        // Fake target to make dependencies work
        // For more info see https://forums.swift.org/t/swiftpm-binary-target-with-sub-dependencies/40197/6
        .target(
            name: "PulseUIWrapper",
            dependencies: [.target(name: "PulseUI"), .product(name: "PulseCore", package: "Pulse")]
        ),
        .binaryTarget(
            name: "PulseUI",
            url: "https://github.com/kean/Pulse/files/5948457/PulseUI-0.9.0.zip",
            checksum: "3a50239dfbc620638f81fd7dba32dab3f05e823d65f7c2e3547b72f0a0c11709"
        )
    ]
)
