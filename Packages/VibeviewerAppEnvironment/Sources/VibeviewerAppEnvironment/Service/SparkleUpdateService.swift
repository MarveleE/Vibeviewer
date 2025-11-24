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
        
        // 使用 NotificationCenter 监听更新状态
        // Sparkle 2.x 使用 SPU 前缀的通知名称
        // 注意：Sparkle 2.x 的通知名称可能有所不同，这里使用常见的名称
        let finishCheckName = NSNotification.Name("SUUpdaterDidFinishUpdateCheck")
        let foundUpdateName = NSNotification.Name("SUUpdaterDidFindValidUpdate")
        let notFoundUpdateName = NSNotification.Name("SUUpdaterDidNotFindUpdate")
        let errorName = NSNotification.Name("SUUpdaterDidEncounterError")
        
        // 也尝试 Sparkle 2.x 的新通知名称
        let spuFinishCheckName = NSNotification.Name("SPUUpdaterDidFinishUpdateCheck")
        let spuFoundUpdateName = NSNotification.Name("SPUUpdaterDidFindValidUpdate")
        let spuNotFoundUpdateName = NSNotification.Name("SPUUpdaterDidNotFindUpdate")
        let spuErrorName = NSNotification.Name("SPUUpdaterDidEncounterError")
        
        // 监听旧版通知（兼容性）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updaterDidFinishUpdateCheck),
            name: finishCheckName,
            object: updaterController.updater
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updaterDidFindValidUpdate(_:)),
            name: foundUpdateName,
            object: updaterController.updater
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updaterDidNotFindUpdate),
            name: notFoundUpdateName,
            object: updaterController.updater
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updaterDidEncounterError(_:)),
            name: errorName,
            object: updaterController.updater
        )
        
        // 监听新版通知（Sparkle 2.x）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updaterDidFinishUpdateCheck),
            name: spuFinishCheckName,
            object: updaterController.updater
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updaterDidFindValidUpdate(_:)),
            name: spuFoundUpdateName,
            object: updaterController.updater
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updaterDidNotFindUpdate),
            name: spuNotFoundUpdateName,
            object: updaterController.updater
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updaterDidEncounterError(_:)),
            name: spuErrorName,
            object: updaterController.updater
        )
        
        // 打印 feedURL 用于调试
        print("[SparkleUpdateService] 初始化完成，feedURL: \(feedURL.absoluteString)")
        print("[SparkleUpdateService] 当前版本: \(currentVersion)")
    }
    
    @objc private func updaterDidFinishUpdateCheck() {
        _isCheckingForUpdates = false
        _lastUpdateCheckDate = Date()
    }
    
    @objc private func updaterDidFindValidUpdate(_ notification: Notification) {
        _updateAvailable = true
        // 尝试从通知中获取版本信息
        // Sparkle 2.x 可能使用不同的键，这里尝试多种可能
        if let versionString = notification.userInfo?["versionString"] as? String {
            _latestVersion = versionString
        } else if let appcastItem = notification.userInfo?["SUAppcastItem"] as? AnyObject,
                  let version = appcastItem.value(forKey: "versionString") as? String {
            _latestVersion = version
        }
    }
    
    @objc private func updaterDidNotFindUpdate() {
        _updateAvailable = false
        _latestVersion = nil
        _isCheckingForUpdates = false
        print("[SparkleUpdateService] 未发现更新")
    }
    
    @objc private func updaterDidEncounterError(_ notification: Notification) {
        _isCheckingForUpdates = false
        _updateAvailable = false
        
        // 尝试从通知中获取错误信息
        if let error = notification.userInfo?["error"] as? NSError {
            print("[SparkleUpdateService] ❌ 更新检查错误: \(error.localizedDescription)")
            print("[SparkleUpdateService] 错误域: \(error.domain), 错误码: \(error.code)")
            
            // 打印完整的错误信息
            print("[SparkleUpdateService] 完整错误信息: \(error)")
            
            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("[SparkleUpdateService] 底层错误: \(underlyingError.localizedDescription)")
                print("[SparkleUpdateService] 底层错误域: \(underlyingError.domain), 错误码: \(underlyingError.code)")
            }
            
            // 检查是否是网络错误
            if error.domain == NSURLErrorDomain {
                switch error.code {
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
                    print("[SparkleUpdateService] 网络错误: \(error.localizedDescription)")
                }
            }
        } else if let errorString = notification.userInfo?["error"] as? String {
            print("[SparkleUpdateService] ❌ 更新检查错误: \(errorString)")
        } else {
            print("[SparkleUpdateService] ❌ 更新检查遇到未知错误")
            print("[SparkleUpdateService] 通知信息: \(notification.userInfo ?? [:])")
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
    
    public func checkForUpdates() {
        print("[SparkleUpdateService] 开始检查更新...")
        print("[SparkleUpdateService] feedURL: \(feedURL.absoluteString)")
        _isCheckingForUpdates = true
        updaterController.checkForUpdates(nil)
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
}


