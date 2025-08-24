import ProjectDescription

let workspaceName = "Vibeviewer"

let project = Project(
  name: workspaceName,
  organizationName: "Vibeviewer",
  options: .options(
    developmentRegion: "en",
    disableBundleAccessors: false,
    disableSynthesizedResourceAccessors: false
  ),
  packages: [
    .local(path: "Packages/VibeviewerCore"),
    .local(path: "Packages/VibeviewerModel"),
    .local(path: "Packages/VibeviewerAPI"),
    .local(path: "Packages/VibeviewerLoginUI"),
    .local(path: "Packages/VibeviewerMenuUI"),
    .local(path: "Packages/VibeviewerSettingsUI"),
    .local(path: "Packages/VibeviewerAppEnvironment"),
  ],
  settings: .settings(
    base: [
      "SWIFT_VERSION": "5.10",
      "MACOSX_DEPLOYMENT_TARGET": "14.0",
    ]
  ),
  targets: [
    .target(
      name: workspaceName,
      destinations: .macOS,
      product: .app,
      bundleId: "com.magicgroot.vibeviewer",
      deploymentTargets: .macOS("14.0"),
      infoPlist: .extendingDefault(with: [
        "LSMinimumSystemVersion": .string("14.0"),
        "LSApplicationCategoryType": .string("public.app-category.productivity"),
      ]),
      sources: ["Vibeviewer/**"],
      resources: [
        "Vibeviewer/Assets.xcassets",
        "Vibeviewer/Preview Content/**",
      ],
      dependencies: [
        .package(product: "VibeviewerAPI"),
        .package(product: "VibeviewerModel"),
        .package(product: "VibeviewerCore"),
        .package(product: "VibeviewerLoginUI"),
        .package(product: "VibeviewerMenuUI"),
        .package(product: "VibeviewerSettingsUI"),
        .package(product: "VibeviewerAppEnvironment"),
      ]
    )
  ]
)
