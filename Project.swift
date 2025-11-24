import ProjectDescription

let workspaceName = "Vibeviewer"

// 版本号统一配置 - 只在这里修改版本号
let appVersion = "1.1.11"

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
        .local(path: "Packages/VibeviewerStorage"),
        .local(path: "Packages/VibeviewerShareUI"),
    ],
    settings: .settings(base: [
        "SWIFT_VERSION": .string("5.10"),
        "MACOSX_DEPLOYMENT_TARGET": .string("14.0"),
        // 代码签名配置 - 确保 Release 构建使用相同的签名
        "CODE_SIGN_IDENTITY": .string("$(CODE_SIGN_IDENTITY)"),
        "CODE_SIGN_STYLE": .string("Automatic"),
        "DEVELOPMENT_TEAM": .string("$(DEVELOPMENT_TEAM)"),
        // 版本信息 - 使用统一的版本号常量
        "MARKETING_VERSION": .string(appVersion),
        "CURRENT_PROJECT_VERSION": .string(appVersion),
    ]),
    targets: [
        .target(
            name: workspaceName,
            destinations: .macOS,
            product: .app,
            bundleId: "com.magicgroot.vibeviewer",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "LSUIElement": .boolean(true),
                "LSMinimumSystemVersion": .string("14.0"),
                "LSApplicationCategoryType": .string("public.app-category.productivity"),
                "UIAppFonts": .array([.string("Satoshi-Regular.ttf"), .string("Satoshi-Medium.ttf"), .string("Satoshi-Bold.ttf"), .string("Satoshi-Italic.ttf")]),
                // 版本信息 - 使用统一的版本号常量
                "CFBundleShortVersionString": .string(appVersion),
                "CFBundleVersion": .string(appVersion),
                // Sparkle 自动更新配置
                // 使用 GitHub Pages 托管 appcast.xml（推荐）
                "SUFeedURL": .string("https://raw.githubusercontent.com/MarveleE/Vibeviewer/refs/heads/feat/auto-update/appcast.xml"),
                "SUEnableAutomaticChecks": .boolean(true),
                "SUEnableAutomaticDownloading": .boolean(false),
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
                .package(product: "VibeviewerStorage"),
                .package(product: "VibeviewerShareUI"),
            ]
        )
    ]
)
