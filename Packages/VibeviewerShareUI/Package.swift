// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "VibeviewerShareUI",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "VibeviewerShareUI", targets: ["VibeviewerShareUI"])
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "VibeviewerShareUI",
      dependencies: []
    ),
    .testTarget(name: "VibeviewerShareUITests", dependencies: ["VibeviewerShareUI"]),
  ]
)


