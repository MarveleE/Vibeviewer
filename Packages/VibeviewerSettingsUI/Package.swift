// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "VibeviewerSettingsUI",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "VibeviewerSettingsUI", targets: ["VibeviewerSettingsUI"])
  ],
  dependencies: [
    .package(path: "../VibeviewerModel"),
    .package(path: "../VibeviewerAppEnvironment"),
    .package(path: "../VibeviewerShareUI"),
  ],
  targets: [
    .target(
      name: "VibeviewerSettingsUI",
      dependencies: [
        "VibeviewerModel",
        "VibeviewerAppEnvironment",
        "VibeviewerShareUI",
      ]
    ),
    .testTarget(name: "VibeviewerSettingsUITests", dependencies: ["VibeviewerSettingsUI"]),
  ]
)
