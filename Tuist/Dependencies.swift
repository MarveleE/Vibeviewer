import ProjectDescription

let dependencies = Dependencies(
  swiftPackageManager: .init(
    packages: [
      // 本项目遵循单一来源：仅在 Project.swift 的 `packages` 声明本地包
    ],
    baseSettings: .settings(
      base: [:],
      configurations: [
        .debug(
          name: "Debug",
          settings: [
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone"
          ]),
        .release(
          name: "Release",
          settings: [
            "SWIFT_OPTIMIZATION_LEVEL": "-Owholemodule"
          ]),
      ]
    )
  ),
  platforms: [.macOS]
)
