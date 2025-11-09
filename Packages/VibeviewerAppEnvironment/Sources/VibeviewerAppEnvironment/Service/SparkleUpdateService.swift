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
    
    public nonisolated var currentVersion: String {
        // 获取主应用 bundle（通常是 Bundle.main，但为了确保正确性，我们查找主应用 bundle）
        let mainAppBundle: Bundle = {
            // 方法1: 使用 Bundle.main（在应用运行时应该指向主应用）
            let mainBundle = Bundle.main
            
            // 验证是否是主应用 bundle（通过检查是否有可执行文件路径）
            if mainBundle.bundlePath.hasSuffix(".app") || mainBundle.bundleIdentifier == "com.magicgroot.vibeviewer" {
                return mainBundle
            }
            
            // 方法2: 通过 bundle identifier 查找主应用 bundle
            if let appBundle = Bundle.allBundles.first(where: { bundle in
                bundle.bundleIdentifier == "com.magicgroot.vibeviewer" && bundle.bundlePath.hasSuffix(".app")
            }) {
                return appBundle
            }
            
            // 方法3: 查找所有 bundles，找到 .app bundle
            if let appBundle = Bundle.allBundles.first(where: { bundle in
                bundle.bundlePath.hasSuffix(".app") && !bundle.bundlePath.contains(".framework")
            }) {
                return appBundle
            }
            
            // 如果都找不到，返回 Bundle.main
            return mainBundle
        }()
        
        // 从主应用 bundle 读取版本号
        // 方法1: 使用 object(forInfoDictionaryKey:) - 这个方法会合并所有 Info.plist
        if let version = mainAppBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, !version.isEmpty {
            return version
        }
        
        // 方法2: 直接从 infoDictionary 读取
        if let version = mainAppBundle.infoDictionary?["CFBundleShortVersionString"] as? String, !version.isEmpty {
            return version
        }
        
        // 方法3: 尝试从 CFBundleVersion 读取（构建号）
        if let version = mainAppBundle.infoDictionary?["CFBundleVersion"] as? String, !version.isEmpty {
            return version
        }
        
        // 方法4: 从 bundle 路径直接读取 Info.plist（最可靠的方法）
        let infoPlistPath = (mainAppBundle.bundlePath as NSString).appendingPathComponent("Contents/Info.plist")
        if FileManager.default.fileExists(atPath: infoPlistPath),
           let plistData = NSDictionary(contentsOfFile: infoPlistPath),
           let version = plistData["CFBundleShortVersionString"] as? String, !version.isEmpty {
            return version
        }
        
        // 方法5: 尝试使用 path(forResource:ofType:) 读取
        if let infoPlistPath = mainAppBundle.path(forResource: "Info", ofType: "plist"),
           let plistData = NSDictionary(contentsOfFile: infoPlistPath),
           let version = plistData["CFBundleShortVersionString"] as? String, !version.isEmpty {
            return version
        }
        
        // 如果所有方法都失败，打印调试信息并返回默认值
        print("⚠️ Warning: Failed to read version from main app bundle")
        print("   Bundle identifier: \(mainAppBundle.bundleIdentifier ?? "unknown")")
        print("   Bundle path: \(mainAppBundle.bundlePath)")
        print("   Info.plist path: \(infoPlistPath)")
        print("   File exists: \(FileManager.default.fileExists(atPath: infoPlistPath))")
        if let infoDict = mainAppBundle.infoDictionary {
            print("   infoDictionary keys: \(infoDict.keys.joined(separator: ", "))")
        }
        
        // 返回默认值（应该与 Project.swift 中的版本号保持一致）
        return "1.1.6"
    }
    
    public init() {
        // 创建 Sparkle 更新器代理
        let delegate = UpdaterDelegate()
        
        // 创建 Sparkle 更新器控制器
        // 注意：需要保持 updaterController 的引用
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: delegate,
            userDriverDelegate: nil
        )
        
        self.updaterController = controller
        self.updaterDelegate = delegate
        
        // 配置更新检查间隔（24小时）
        controller.updater.updateCheckInterval = 86400 // 24小时
        
        // 设置代理以跟踪更新检查状态
        delegate.onCheckingStateChanged = { [weak self] isChecking in
            Task { @MainActor in
                self?._isCheckingForUpdates = isChecking
            }
        }
    }
    
    public func checkForUpdates() {
        _isCheckingForUpdates = true
        updater.checkForUpdates()
    }
    
    public func checkForUpdatesInBackground() {
        updater.checkForUpdatesInBackground()
    }
}

/// Sparkle 更新器代理
@MainActor
private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    var updateAvailable: Bool = false
    var onCheckingStateChanged: ((Bool) -> Void)?
}

extension UpdaterDelegate {
    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) -> Bool {
        Task { @MainActor in
            self.updateAvailable = true
            self.onCheckingStateChanged?(false)
        }
        return true // 允许更新
    }
    
    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        Task { @MainActor in
            self.updateAvailable = false
            self.onCheckingStateChanged?(false)
        }
    }
    
    nonisolated func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        // 下载失败，可以在这里记录日志
        print("Sparkle: Failed to download update: \(error.localizedDescription)")
        Task { @MainActor in
            self.onCheckingStateChanged?(false)
        }
    }
    
    nonisolated func updaterDidStartUpdateCheck(_ updater: SPUUpdater) {
        Task { @MainActor in
            self.onCheckingStateChanged?(true)
        }
    }
    
    nonisolated func updaterDidFinishUpdateCheck(_ updater: SPUUpdater) {
        Task { @MainActor in
            self.onCheckingStateChanged?(false)
        }
    }
}

