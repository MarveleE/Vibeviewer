// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "VibeviewerCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "VibeviewerCore", targets: ["VibeviewerCore"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "VibeviewerCore", dependencies: []),
        .testTarget(name: "VibeviewerCoreTests", dependencies: ["VibeviewerCore"])
    ]
)
