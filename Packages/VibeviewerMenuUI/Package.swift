// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "VibeviewerMenuUI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "VibeviewerMenuUI", targets: ["VibeviewerMenuUI"]),
    ],
    dependencies: [
        .package(path: "../VibeviewerModel"),
        .package(path: "../VibeviewerAPI"),
        .package(path: "../VibeviewerLoginUI"),
        .package(path: "../VibeviewerSettingsUI"),
    ],
    targets: [
        .target(
            name: "VibeviewerMenuUI",
            dependencies: [
                "VibeviewerModel",
                "VibeviewerAPI",
                "VibeviewerLoginUI",
                "VibeviewerSettingsUI"
            ]
        ),
        .testTarget(name: "VibeviewerMenuUITests", dependencies: ["VibeviewerMenuUI"]) 
    ]
)


