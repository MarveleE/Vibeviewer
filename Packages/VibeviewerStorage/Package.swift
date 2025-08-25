// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "VibeviewerStorage",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "VibeviewerStorage", targets: ["VibeviewerStorage"])
    ],
    dependencies: [
        .package(path: "../VibeviewerModel")
    ],
    targets: [
        .target(
            name: "VibeviewerStorage",
            dependencies: [
                .product(name: "VibeviewerModel", package: "VibeviewerModel")
            ]
        ),
        .testTarget(
            name: "VibeviewerStorageTests",
            dependencies: ["VibeviewerStorage"]
        )
    ]
)


