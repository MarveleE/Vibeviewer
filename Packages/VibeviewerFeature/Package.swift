// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "VibeviewerFeature",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "VibeviewerFeature", targets: ["VibeviewerFeature"]),
    ],
    dependencies: [
        .package(path: "../VibeviewerAPI"),
        .package(path: "../VibeviewerModel")
    ],
    targets: [
        .target(
            name: "VibeviewerFeature",
            dependencies: [
                "VibeviewerAPI",
                "VibeviewerModel"
            ]
        ),
        .testTarget(name: "VibeviewerFeatureTests", dependencies: ["VibeviewerFeature"]) 
    ]
)
