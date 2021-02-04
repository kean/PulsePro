// swift-tools-version:5.2
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
        .library(name: "PulseUI", targets: ["PulseUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Pulse.git", from: "0.5.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "PulseUI", dependencies: ["Pulse"], path: "Sources")
    ]
)
