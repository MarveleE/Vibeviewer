// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "VibeviewerAPI",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "VibeviewerAPI", targets: ["VibeviewerAPI"])
  ],
  dependencies: [
    .package(path: "../VibeviewerModel"),
    .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "15.0.0")),
    .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.8.0")),
  ],
  targets: [
    .target(
      name: "VibeviewerAPI",
      dependencies: [
        "VibeviewerModel",
        .product(name: "Moya", package: "Moya"),
        .product(name: "Alamofire", package: "Alamofire"),
      ]
    ),
    .testTarget(name: "VibeviewerAPITests", dependencies: ["VibeviewerAPI"]),
  ]
)
