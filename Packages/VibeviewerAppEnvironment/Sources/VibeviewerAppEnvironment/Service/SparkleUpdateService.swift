//
//  SparkleUpdateService.swift
//  VibeviewerAppEnvironment
//
//  Created by Groot chen on 2025/8/24.
//

import AppKit
import Foundation
import Sparkle

/// Sparkle 更新服务实现
@MainActor
public final class SparkleUpdateService: UpdateService, @unchecked Sendable {
    // 需要保持 updaterController 的引用，否则会被释放
    private let updaterController: SPUStandardUpdaterController
    private let updaterDelegate: UpdaterDelegate
    
    // 跟踪更新检查状态
    private var _isCheckingForUpdates: Bool = false
    
    private var updater: SPUUpdater {
        updaterController.updater
    }
    
    public var isCheckingForUpdates: Bool {
        _isCheckingForUpdates
    }
    
    public var updateAvailable: Bool {
        updaterDelegate.updateAvailable
    }
    
    public var latestVersion: String? {
        updaterDelegate.latestVersion
    }
    
    public var lastUpdateCheckDate: Date? {
        updaterDelegate.lastUpdateCheckDate
    }
    
    public var updateStatusDescription: String {
        if isCheckingForUpdates {
            return "Checking for updates..."
        }
        
        if updateAvailable, let latest = latestVersion {
            return "Update available: \(latest)"
        }
        
        if let lastCheck = lastUpdateCheckDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            let relativeTime = formatter.localizedString(for: lastCheck, relativeTo: Date())
            return "Up to date (checked \(relativeTime))"
        }
        
        return "Not checked yet"
    }
    
    public nonisolated var currentVersion: String {
        // 使用 Bundle.main 读取版本号（macOS 应用运行时总是正确的）
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, !version.isEmpty {
            return version
        }
        
        // Fallback: 尝试从 CFBundleVersion 读取
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String, !version.isEmpty {
            return version
        }
        
        // 如果都失败，返回默认值（应该与 Project.swift 中的版本号保持一致）
        return "1.1.5"
    }
    
    public init() {
        // 创建 Sparkle 更新器代理
        let delegate = UpdaterDelegate()
        
        // 创建 Sparkle 更新器控制器
        // 注意：对于 MenuBar 应用（LSUIElement = true），传递 nil 作为 userDriverDelegate
        // Sparkle 会自动使用默认的用户驱动来处理更新界面
        // 需要保持 updaterController 的引用，否则会被释放
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: delegate,
            userDriverDelegate: nil
        )
        
        self.updaterController = controller
        self.updaterDelegate = delegate
        
        // 配置更新器以确保正确工作
        let updater = controller.updater
        
        // 确保自动更新检查已启用
        updater.automaticallyChecksForUpdates = true
        
        // 配置更新检查间隔（24小时）
        updater.updateCheckInterval = 86400 // 24小时
        
        // 验证 Feed URL 配置
        let feedURL = updater.feedURL
        print("📦 Sparkle: 初始化更新服务")
        print("   Feed URL: \(feedURL?.absoluteString ?? "未配置")")
        print("   检查间隔: \(updater.updateCheckInterval) 秒")
        print("   自动检查: \(updater.automaticallyChecksForUpdates)")
        print("   Bundle ID: \(Bundle.main.bundleIdentifier ?? "未知")")
        
        // 设置代理以跟踪更新检查状态
        delegate.onCheckingStateChanged = { [weak self] isChecking in
            Task { @MainActor in
                self?._isCheckingForUpdates = isChecking
            }
        }
    }
    
    public func checkForUpdates() {
        // 确保在主线程上执行
        assert(Thread.isMainThread, "checkForUpdates must be called on main thread")
        
        print("🔍 Sparkle: 开始检查更新...")
        print("   Feed URL: \(updater.feedURL?.absoluteString ?? "未配置")")
        print("   Current version: \(currentVersion)")
        
        _isCheckingForUpdates = true
        updater.checkForUpdates()
    }
    
    public func checkForUpdatesInBackground() {
        // 确保在主线程上执行
        assert(Thread.isMainThread, "checkForUpdatesInBackground must be called on main thread")
        
        print("🔍 Sparkle: 后台检查更新...")
        updater.checkForUpdatesInBackground()
    }
}

/// Sparkle 更新器代理
@MainActor
private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    var updateAvailable: Bool = false
    var latestVersion: String?
    var lastUpdateCheckDate: Date?
    var onCheckingStateChanged: ((Bool) -> Void)?
}

extension UpdaterDelegate {
    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) -> Bool {
        print("✅ Sparkle: 找到可用更新")
        print("   版本: \(item.versionString)")
        print("   显示版本: \(item.displayVersionString)")
        print("   发布日期: \(item.dateString ?? "未知")")
        print("   下载 URL: \(item.fileURL?.absoluteString ?? "未知")")
        print("   更新标题: \(item.title ?? "未知")")
        
        Task { @MainActor in
            self.updateAvailable = true
            self.latestVersion = item.displayVersionString.isEmpty ? item.versionString : item.displayVersionString
            self.lastUpdateCheckDate = Date()
            self.onCheckingStateChanged?(false)
        }
        
        // 返回 true 允许更新，Sparkle 会自动处理下载和安装
        return true
    }
    
    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        print("ℹ️ Sparkle: 未找到更新")
        if let nsError = error as NSError? {
            print("   错误域: \(nsError.domain)")
            print("   错误代码: \(nsError.code)")
            print("   错误描述: \(nsError.localizedDescription)")
            if !nsError.userInfo.isEmpty {
                print("   详细信息: \(nsError.userInfo)")
            }
        } else {
            print("   错误: \(error.localizedDescription)")
        }
        
        Task { @MainActor in
            self.updateAvailable = false
            self.latestVersion = nil
            self.lastUpdateCheckDate = Date()
            self.onCheckingStateChanged?(false)
        }
    }
    
    nonisolated func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        print("❌ Sparkle: 下载更新失败")
        print("   版本: \(item.versionString)")
        print("   下载 URL: \(item.fileURL?.absoluteString ?? "未知")")
        print("   错误: \(error.localizedDescription)")
        if let nsError = error as NSError? {
            print("   错误域: \(nsError.domain)")
            print("   错误代码: \(nsError.code)")
            if !nsError.userInfo.isEmpty {
                print("   详细信息: \(nsError.userInfo)")
            }
        }
        
        Task { @MainActor in
            self.onCheckingStateChanged?(false)
        }
    }
    
    nonisolated func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        print("📦 Sparkle: 准备安装更新")
        print("   版本: \(item.versionString)")
        print("   显示版本: \(item.displayVersionString)")
        print("   下载 URL: \(item.fileURL?.absoluteString ?? "未知")")
        print("   ⚠️  注意: 应用将在安装更新后退出并重启")
    }
    
    nonisolated func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        if let error = error {
            print("⚠️ Sparkle: 更新周期完成，但有错误")
            print("   错误: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   错误域: \(nsError.domain)")
                print("   错误代码: \(nsError.code)")
                if !nsError.userInfo.isEmpty {
                    print("   详细信息: \(nsError.userInfo)")
                }
            }
        } else {
            print("✅ Sparkle: 更新周期完成")
        }
    }
    
    nonisolated func updaterDidStartUpdateCheck(_ updater: SPUUpdater) {
        print("🔄 Sparkle: 更新检查已开始")
        Task { @MainActor in
            self.onCheckingStateChanged?(true)
        }
    }
    
    nonisolated func updaterDidFinishUpdateCheck(_ updater: SPUUpdater) {
        print("✨ Sparkle: 更新检查已完成")
        Task { @MainActor in
            self.onCheckingStateChanged?(false)
        }
    }
}

