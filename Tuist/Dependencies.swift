import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: .init(
        packages: [
            .local(path: "Packages/VibeviewerCore"),
            .local(path: "Packages/VibeviewerModel"),
            .local(path: "Packages/VibeviewerAPI"),
            .local(path: "Packages/VibeviewerLoginUI"),
            .local(path: "Packages/VibeviewerMenuUI"),
            .local(path: "Packages/VibeviewerSettingsUI")
        ],
        baseSettings: .settings(
            base: [:],
            configurations: [
                .debug(name: "Debug", settings: [
                    "SWIFT_OPTIMIZATION_LEVEL": "-Onone"
                ]),
                .release(name: "Release", settings: [
                    "SWIFT_OPTIMIZATION_LEVEL": "-Owholemodule"
                ])
            ]
        )
    ),
    platforms: [.macOS]
)


