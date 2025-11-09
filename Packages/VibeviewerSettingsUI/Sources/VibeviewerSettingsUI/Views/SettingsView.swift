import Observation
import SwiftUI
import VibeviewerAppEnvironment
import VibeviewerModel
import VibeviewerShareUI

public struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.cursorStorage) private var storage
    @Environment(\.launchAtLoginService) private var launchAtLoginService
    @Environment(\.dashboardRefreshService) private var refresher
    @Environment(\.updateService) private var updateService
    @Environment(AppSession.self) private var session
    
    @State private var refreshFrequency: Int = 5
    @State private var usageHistoryLimit: Int = 5
    @State private var pauseOnScreenSleep: Bool = false
    @State private var launchAtLogin: Bool = false
    @State private var appearanceSelection: VibeviewerModel.AppAppearance = .system
    @State private var showingClearSessionAlert: Bool = false
    @State private var showingLogoutAlert: Bool = false
    @State private var analyticsDataDays: Int = 7
    
    // 预定义选项
    private let refreshFrequencyOptions: [Int] = [1, 2, 3, 5, 10, 15, 30]
    private let usageHistoryLimitOptions: [Int] = [5, 10, 20, 50, 100]
    private let analyticsDataDaysOptions: [Int] = [3, 7, 14, 30, 60, 90]

    public init() {}

    public var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $appearanceSelection) {
                    Text("System").tag(VibeviewerModel.AppAppearance.system)
                    Text("Light").tag(VibeviewerModel.AppAppearance.light)
                    Text("Dark").tag(VibeviewerModel.AppAppearance.dark)
                }
                .onChange(of: appearanceSelection) { oldValue, newValue in
                    appSettings.appearance = newValue
                    Task { @MainActor in
                        try? await appSettings.save(using: storage)
                    }
                }
                
                // 版本信息
                HStack {
                    Text("Current Version")
                    Spacer()
                    Text(updateService.currentVersion)
                        .foregroundColor(.secondary)
                }
                
                // 最新版本（如果有更新）
                if let latestVersion = updateService.latestVersion {
                    HStack {
                        Text("Latest Version")
                        Spacer()
                        HStack(spacing: 4) {
                            Text(latestVersion)
                                .foregroundColor(.blue)
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                        }
                    }
                }
                
                // 更新状态
                HStack {
                    Text("Update Status")
                    Spacer()
                    Text(updateService.updateStatusDescription)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
                
                // 上次检查时间
                if let lastCheck = updateService.lastUpdateCheckDate {
                    HStack {
                        Text("Last Checked")
                        Spacer()
                        Text(lastCheck, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 检查更新按钮
                Button {
                    // 确保在主线程上调用更新检查
                    Task { @MainActor in
                        updateService.checkForUpdates()
                    }
                } label: {
                    HStack {
                        if updateService.isCheckingForUpdates {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        }
                        Text(updateService.isCheckingForUpdates ? "Checking for Updates..." : "Check for Updates")
                    }
                }
                .disabled(updateService.isCheckingForUpdates)
            } header: {
                Text("General")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    if updateService.updateAvailable {
                        Text("A new version is available. Click 'Check for Updates' to download and install.")
                            .foregroundColor(.blue)
                    } else if updateService.isCheckingForUpdates {
                        Text("Checking for updates...")
                            .foregroundColor(.secondary)
                    } else if let lastCheck = updateService.lastUpdateCheckDate {
                        Text("You're up to date. Last checked \(lastCheck, style: .relative).")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Click 'Check for Updates' to see if a new version is available.")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Picker("Refresh Frequency", selection: $refreshFrequency) {
                    ForEach(refreshFrequencyOptions, id: \.self) { value in
                        Text("\(value) minutes").tag(value)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: refreshFrequency) { oldValue, newValue in
                    appSettings.overview.refreshInterval = newValue
                    Task { @MainActor in
                        try? await appSettings.save(using: storage)
                    }
                }
                
                Picker("Usage History Limit", selection: $usageHistoryLimit) {
                    ForEach(usageHistoryLimitOptions, id: \.self) { value in
                        Text("\(value) items").tag(value)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: usageHistoryLimit) { oldValue, newValue in
                    appSettings.usageHistory.limit = newValue
                    Task { @MainActor in
                        try? await appSettings.save(using: storage)
                    }
                }
                
                Picker("Analytics Data Range", selection: $analyticsDataDays) {
                    ForEach(analyticsDataDaysOptions, id: \.self) { value in
                        Text("\(value) days").tag(value)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: analyticsDataDays) { oldValue, newValue in
                    appSettings.analyticsDataDays = newValue
                    Task { @MainActor in
                        try? await appSettings.save(using: storage)
                    }
                }
            } header: {
                Text("Data")
            } footer: {
                Text("Refresh Frequency: Controls the automatic refresh interval for dashboard data.\nUsage History Limit: Limits the number of usage history items displayed.\nAnalytics Data Range: Controls the number of days of data shown in analytics charts.")
            }
            
            Section {
                Toggle("Pause refresh when screen sleeps", isOn: $pauseOnScreenSleep)
                    .onChange(of: pauseOnScreenSleep) { oldValue, newValue in
                        appSettings.pauseOnScreenSleep = newValue
                        Task { @MainActor in
                            try? await appSettings.save(using: storage)
                        }
                    }
                
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { oldValue, newValue in
                        _ = launchAtLoginService.setEnabled(newValue)
                        appSettings.launchAtLogin = newValue
                        Task { @MainActor in
                            try? await appSettings.save(using: storage)
                        }
                    }
            } header: {
                Text("Behavior")
            }
            
            if session.credentials != nil {
                Section {
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        Text("Log Out")
                    }
                } header: {
                    Text("Account")
                } footer: {
                    Text("Clear login credentials and stop data refresh. You will need to log in again to continue using the app.")
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showingClearSessionAlert = true
                } label: {
                    Text("Clear App Cache")
                }
            } header: {
                Text("Advanced")
            } footer: {
                Text("Clear all stored credentials and dashboard data. You will need to log in again.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 500)
        .onAppear {
            loadSettings()
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                Task { @MainActor in
                    await logout()
                }
            }
        } message: {
            Text("This will clear your login credentials and stop data refresh. You will need to log in again to continue using the app.")
        }
        .alert("Clear App Cache", isPresented: $showingClearSessionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task { @MainActor in
                    await clearAppSession()
                }
            }
        } message: {
            Text("This will clear all stored credentials and dashboard data. You will need to log in again.")
        }
    }
    
    private func loadSettings() {
        // 加载设置值
        let currentRefreshFrequency = appSettings.overview.refreshInterval
        let currentUsageHistoryLimit = appSettings.usageHistory.limit
        let currentAnalyticsDataDays = appSettings.analyticsDataDays
        
        // 如果当前值不在选项中，使用最接近的值并更新设置
        if refreshFrequencyOptions.contains(currentRefreshFrequency) {
            refreshFrequency = currentRefreshFrequency
        } else {
            let closest = refreshFrequencyOptions.min(by: { abs($0 - currentRefreshFrequency) < abs($1 - currentRefreshFrequency) }) ?? 5
            refreshFrequency = closest
            appSettings.overview.refreshInterval = closest
        }
        
        if usageHistoryLimitOptions.contains(currentUsageHistoryLimit) {
            usageHistoryLimit = currentUsageHistoryLimit
        } else {
            let closest = usageHistoryLimitOptions.min(by: { abs($0 - currentUsageHistoryLimit) < abs($1 - currentUsageHistoryLimit) }) ?? 5
            usageHistoryLimit = closest
            appSettings.usageHistory.limit = closest
        }
        
        if analyticsDataDaysOptions.contains(currentAnalyticsDataDays) {
            analyticsDataDays = currentAnalyticsDataDays
        } else {
            let closest = analyticsDataDaysOptions.min(by: { abs($0 - currentAnalyticsDataDays) < abs($1 - currentAnalyticsDataDays) }) ?? 7
            analyticsDataDays = closest
            appSettings.analyticsDataDays = closest
        }
        
        pauseOnScreenSleep = appSettings.pauseOnScreenSleep
        launchAtLogin = launchAtLoginService.isEnabled
        appearanceSelection = appSettings.appearance
        
        // 如果值被调整了，保存设置
        if !refreshFrequencyOptions.contains(currentRefreshFrequency) ||
           !usageHistoryLimitOptions.contains(currentUsageHistoryLimit) ||
           !analyticsDataDaysOptions.contains(currentAnalyticsDataDays) {
            Task { @MainActor in
                try? await appSettings.save(using: storage)
            }
        }
    }
    
    private func logout() async {
        // 停止刷新服务
        refresher.stop()
        
        // 清空存储的凭据
        await storage.clearCredentials()
        
        // 重置内存中的凭据
        session.credentials = nil
        
        // 关闭设置窗口
        NSApplication.shared.keyWindow?.close()
    }
    
    private func clearAppSession() async {
        // 停止刷新服务
        refresher.stop()
        
        // 清空存储的 AppSession 数据
        await storage.clearAppSession()
        
        // 重置内存中的 AppSession
        session.credentials = nil
        session.snapshot = nil
        
        // 关闭设置窗口
        NSApplication.shared.keyWindow?.close()
    }
}
