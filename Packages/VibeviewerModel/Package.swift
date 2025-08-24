// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "VibeviewerModel",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "VibeviewerModel", targets: ["VibeviewerModel"]),
    ],
    dependencies: [
        .package(path: "../VibeviewerCore")
    ],
    targets: [
        .target(name: "VibeviewerModel", dependencies: ["VibeviewerCore"]),
        .testTarget(name: "VibeviewerModelTests", dependencies: ["VibeviewerModel"])
    ]
)
