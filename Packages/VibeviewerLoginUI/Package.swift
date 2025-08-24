// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "VibeviewerLoginUI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "VibeviewerLoginUI", targets: ["VibeviewerLoginUI"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VibeviewerLoginUI",
            dependencies: []
        ),
        .testTarget(name: "VibeviewerLoginUITests", dependencies: ["VibeviewerLoginUI"]) 
    ]
)


