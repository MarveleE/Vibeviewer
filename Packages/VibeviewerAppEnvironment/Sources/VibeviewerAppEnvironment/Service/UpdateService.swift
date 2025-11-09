import Foundation

/// 应用更新服务协议
public protocol UpdateService: Sendable {
    /// 检查更新（手动触发）
    @MainActor func checkForUpdates()
    
    /// 自动检查更新（在应用启动时调用）
    @MainActor func checkForUpdatesInBackground()
    
    /// 是否正在检查更新
    @MainActor var isCheckingForUpdates: Bool { get }
    
    /// 是否有可用更新
    @MainActor var updateAvailable: Bool { get }
    
    /// 当前版本信息
    var currentVersion: String { get }
    
    /// 最新可用版本号（如果有更新）
    @MainActor var latestVersion: String? { get }
    
    /// 上次检查更新的时间
    @MainActor var lastUpdateCheckDate: Date? { get }
    
    /// 更新状态描述
    @MainActor var updateStatusDescription: String { get }
}

/// 无操作默认实现，便于提供 Environment 默认值
public struct NoopUpdateService: UpdateService {
    public init() {}
    
    @MainActor public func checkForUpdates() {}
    @MainActor public func checkForUpdatesInBackground() {}
    @MainActor public var isCheckingForUpdates: Bool { false }
    @MainActor public var updateAvailable: Bool { false }
    public var currentVersion: String {
        // 使用 Bundle.main 读取版本号
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, !version.isEmpty {
            return version
        }
        // Fallback: 尝试从 CFBundleVersion 读取
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String, !version.isEmpty {
            return version
        }
        // 默认版本号
        return "1.1.9"
    }
    @MainActor public var latestVersion: String? { nil }
    @MainActor public var lastUpdateCheckDate: Date? { nil }
    @MainActor public var updateStatusDescription: String { "更新服务不可用" }
}

