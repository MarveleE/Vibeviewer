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
    dependencies: [
        .package(path: "../VibeviewerShareUI")
    ],
    targets: [
        .target(
            name: "VibeviewerLoginUI",
            dependencies: [
                "VibeviewerShareUI"
            ]
        ),
        .testTarget(name: "VibeviewerLoginUITests", dependencies: ["VibeviewerLoginUI"]) 
    ]
)


