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
        .local(path: "Packages/VibeviewerStorage"),
        .local(path: "Packages/VibeviewerShareUI"),
        .remote(url: "https://github.com/sparkle-project/Sparkle", requirement: .upToNextMajor(from: "2.6.0")),
    ],
    settings: .settings(base: [
        "SWIFT_VERSION": "5.10",
        "MACOSX_DEPLOYMENT_TARGET": "14.0",
        // 代码签名配置 - 确保 Release 构建使用相同的签名
        "CODE_SIGN_IDENTITY": "$(CODE_SIGN_IDENTITY)",
        "CODE_SIGN_STYLE": "Automatic",
        "DEVELOPMENT_TEAM": "$(DEVELOPMENT_TEAM)",
        // 版本信息 - 确保版本号正确传递
        "MARKETING_VERSION": "1.1.6",
        "CURRENT_PROJECT_VERSION": "1.1.6",
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
                // 版本信息
                "CFBundleShortVersionString": .string("1.1.6"),
                "CFBundleVersion": .string("1.1.6"),
                // Sparkle 更新配置
                "SUFeedURL": .string("https://raw.githubusercontent.com/MarveleE/Vibeviewer/main/appcast.xml"),
                "SUPublicEDSAKey": .string("HkePEJXQXvz+idowO2tZ9g/J01nY+seiKUonETPG5+A="),
                "SUScheduledCheckInterval": .integer(86400), // 24小时
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
                .package(product: "Sparkle"),
            ]
        )
    ]
)
