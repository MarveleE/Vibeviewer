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
}

/// 无操作默认实现，便于提供 Environment 默认值
public struct NoopUpdateService: UpdateService {
    public init() {}
    
    @MainActor public func checkForUpdates() {}
    @MainActor public func checkForUpdatesInBackground() {}
    @MainActor public var isCheckingForUpdates: Bool { false }
    @MainActor public var updateAvailable: Bool { false }
    public var currentVersion: String { "1.0.0" }
}

