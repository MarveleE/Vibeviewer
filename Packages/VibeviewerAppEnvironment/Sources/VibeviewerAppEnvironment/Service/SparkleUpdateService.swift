import Foundation
import Sparkle

/// Sparkle 更新服务实现
@MainActor
@Observable
public final class SparkleUpdateService: NSObject, UpdateService, SPUUpdaterDelegate {
    private var updaterController: SPUStandardUpdaterController!
    private let feedURL: URL
    private var _isCheckingForUpdates: Bool = false
    private var _updateAvailable: Bool = false
    private var _latestVersion: String?
    private var _lastUpdateCheckDate: Date?
    private var checkTimeoutTask: Task<Void, Never>?
    
    public init(feedURL: URL) {
        self.feedURL = feedURL
        
        super.init()
        
        // 创建更新器控制器，设置 self 作为 delegate 以提供 feedURL
        // 注意：必须在 super.init() 之后才能使用 self
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        
        // 配置自动检查（但不自动下载）
        UserDefaults.standard.set(true, forKey: "SUEnableAutomaticChecks")
        UserDefaults.standard.set(false, forKey: "SUEnableAutomaticDownloading")
        
        // 打印 feedURL 用于调试
        print("[SparkleUpdateService] 初始化完成，feedURL: \(feedURL.absoluteString)")
        print("[SparkleUpdateService] 当前版本: \(currentVersion)")
    }
    
    public func checkForUpdates() {
        print("[SparkleUpdateService] 开始检查更新...")
        print("[SparkleUpdateService] feedURL: \(feedURL.absoluteString)")
        
        // 取消之前的超时任务
        checkTimeoutTask?.cancel()
        
        _isCheckingForUpdates = true
        updaterController.checkForUpdates(nil)
        
        // 设置超时：如果 30 秒后还没有收到任何回调，自动重置状态
        checkTimeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(30))
            if _isCheckingForUpdates {
                print("[SparkleUpdateService] ⚠️ 更新检查超时，自动重置状态")
                _isCheckingForUpdates = false
                _lastUpdateCheckDate = Date()
            }
        }
    }
    
    public func checkForUpdatesInBackground() {
        updaterController.updater.checkForUpdatesInBackground()
    }
    
    public var isCheckingForUpdates: Bool {
        _isCheckingForUpdates
    }
    
    public var updateAvailable: Bool {
        _updateAvailable
    }
    
    public var currentVersion: String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, !version.isEmpty {
            return version
        }
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String, !version.isEmpty {
            return version
        }
        return "1.1.9"
    }
    
    public var latestVersion: String? {
        _latestVersion
    }
    
    public var lastUpdateCheckDate: Date? {
        _lastUpdateCheckDate
    }
    
    public var updateStatusDescription: String {
        if _isCheckingForUpdates {
            return "正在检查更新..."
        }
        if _updateAvailable, let latest = _latestVersion {
            return "发现新版本: \(latest)"
        }
        if let lastCheck = _lastUpdateCheckDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "上次检查: \(formatter.string(from: lastCheck))"
        }
        return "已是最新版本"
    }
    
    // MARK: - SPUUpdaterDelegate
    
    /// 为 Sparkle 提供 appcast feed URL
    public func feedURLString(for updater: SPUUpdater) -> String? {
        return feedURL.absoluteString
    }
    
    /// 找到有效更新
    public func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        checkTimeoutTask?.cancel()
        _updateAvailable = true
        _latestVersion = item.versionString
        _isCheckingForUpdates = false
        _lastUpdateCheckDate = Date()
        print("[SparkleUpdateService] 发现新版本: \(item.versionString)")
    }
    
    /// 未找到更新
    public func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        checkTimeoutTask?.cancel()
        _updateAvailable = false
        _latestVersion = nil
        _isCheckingForUpdates = false
        _lastUpdateCheckDate = Date()
        print("[SparkleUpdateService] 未发现更新，当前已是最新版本")
    }
    
    /// 更新检查失败
    public func updater(_ updater: SPUUpdater, didFailToCheckForUpdatesWithError error: Error) {
        checkTimeoutTask?.cancel()
        _isCheckingForUpdates = false
        _updateAvailable = false
        
        let nsError = error as NSError
        print("[SparkleUpdateService] ❌ 更新检查错误: \(nsError.localizedDescription)")
        print("[SparkleUpdateService] 错误域: \(nsError.domain), 错误码: \(nsError.code)")
        
        // 打印完整的错误信息
        print("[SparkleUpdateService] 完整错误信息: \(nsError)")
        
        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            print("[SparkleUpdateService] 底层错误: \(underlyingError.localizedDescription)")
            print("[SparkleUpdateService] 底层错误域: \(underlyingError.domain), 错误码: \(underlyingError.code)")
        }
        
        // 检查是否是网络错误
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                print("[SparkleUpdateService] 网络错误: 未连接到互联网")
            case NSURLErrorTimedOut:
                print("[SparkleUpdateService] 网络错误: 请求超时")
            case NSURLErrorCannotFindHost:
                print("[SparkleUpdateService] 网络错误: 无法找到主机")
            case NSURLErrorCannotConnectToHost:
                print("[SparkleUpdateService] 网络错误: 无法连接到主机")
            case NSURLErrorBadURL:
                print("[SparkleUpdateService] 网络错误: URL 格式错误")
            default:
                print("[SparkleUpdateService] 网络错误: \(nsError.localizedDescription)")
            }
        }
        
        // 打印 feedURL 用于调试
        print("[SparkleUpdateService] 当前 feedURL: \(feedURL.absoluteString)")
        print("[SparkleUpdateService] ⚠️ 请检查:")
        print("[SparkleUpdateService]   1. feedURL 是否正确且可访问（当前 URL 可能返回 404）")
        print("[SparkleUpdateService]   2. appcast.xml 文件是否存在且格式正确")
        print("[SparkleUpdateService]   3. 网络连接是否正常")
        print("[SparkleUpdateService]   4. 如果使用 GitHub releases，URL 格式应为:")
        print("[SparkleUpdateService]      https://github.com/owner/repo/releases/download/tag/appcast.xml")
        print("[SparkleUpdateService]      或使用 GitHub Pages:")
        print("[SparkleUpdateService]      https://username.github.io/repo/appcast.xml")
    }
}


