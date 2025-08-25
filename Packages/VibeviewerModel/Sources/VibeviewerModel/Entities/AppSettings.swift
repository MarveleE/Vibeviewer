import Foundation

public struct AppSettings: Codable, Sendable, Equatable {
    public var launchAtLogin: Bool
    public var showNotifications: Bool
    public var enableNetworkLog: Bool

    public init(
        launchAtLogin: Bool = false,
        showNotifications: Bool = true,
        enableNetworkLog: Bool = true
    ) {
        self.launchAtLogin = launchAtLogin
        self.showNotifications = showNotifications
        self.enableNetworkLog = enableNetworkLog
    }
}

// 持久化相关逻辑已迁移到 VibeviewerStorage 包
