// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "VibeviewerMenuUI",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "VibeviewerMenuUI", targets: ["VibeviewerMenuUI"])
  ],
  dependencies: [
    .package(path: "../VibeviewerModel"),
    .package(path: "../VibeviewerAppEnvironment"),
    .package(path: "../VibeviewerAPI"),
    .package(path: "../VibeviewerLoginUI"),
    .package(path: "../VibeviewerSettingsUI"),
    .package(path: "../VibeviewerShareUI"),
  ],
  targets: [
    .target(
      name: "VibeviewerMenuUI",
      dependencies: [
        "VibeviewerModel",
        "VibeviewerAppEnvironment",
        "VibeviewerAPI",
        "VibeviewerLoginUI",
        "VibeviewerSettingsUI",
        "VibeviewerShareUI"
      ]
    ),
    .testTarget(name: "VibeviewerMenuUITests", dependencies: ["VibeviewerMenuUI"]),
  ]
)
