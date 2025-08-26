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
    .package(path: "../VibeviewerModel")
  ],
  targets: [
    .target(
      name: "VibeviewerShareUI",
      dependencies: ["VibeviewerModel"],
      resources: [
        // 将自定义字体放入 Sources/VibeviewerShareUI/Fonts/ 下
        // 例如：Satoshi-Regular.otf、Satoshi-Medium.otf、Satoshi-Bold.otf、Satoshi-Italic.otf
        .process("Fonts"),
        .process("Images")
      ]
    ),
    .testTarget(name: "VibeviewerShareUITests", dependencies: ["VibeviewerShareUI"]),
  ]
)
