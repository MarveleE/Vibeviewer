import Observation
import SwiftUI
import VibeviewerAppEnvironment
import VibeviewerModel
import VibeviewerShareUI

public struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.cursorStorage) private var storage
    @Environment(\.launchAtLoginService) private var launchAtLoginService
    @Environment(AppSession.self) private var session
    
    @State private var refreshFrequency: String = ""
    @State private var usageHistoryLimit: String = ""
    @State private var pauseOnScreenSleep: Bool = false
    @State private var launchAtLogin: Bool = false
    @State private var appearanceSelection: VibeviewerModel.AppAppearance = .system
    @State private var showingClearSessionAlert: Bool = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.app(.satoshiBold, size: 18))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Picker("Appearance", selection: $appearanceSelection) {
                    Text("System").tag(VibeviewerModel.AppAppearance.system)
                    Text("Light").tag(VibeviewerModel.AppAppearance.light)
                    Text("Dark").tag(VibeviewerModel.AppAppearance.dark)
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Refresh Frequency (minutes)")
                        .font(.app(.satoshiMedium, size: 12))
                    
                    TextField("5", text: $refreshFrequency)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage History Limit")
                        .font(.app(.satoshiMedium, size: 12))
                    
                    TextField("10", text: $usageHistoryLimit)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
                Toggle("Pause refresh when screen sleeps", isOn: $pauseOnScreenSleep)
                    .font(.app(.satoshiMedium, size: 12))
                
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .font(.app(.satoshiMedium, size: 12))
            }
            
            HStack {
                Spacer()
                
                Button("Close") {
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.vibe(Color(hex: "F58283").opacity(0.8)))
                
                // 清空 AppSession 按钮
                Button("Clear App Cache") {
                    showingClearSessionAlert = true
                }
                .buttonStyle(.vibe(.secondary.opacity(0.8)))
                .font(.app(.satoshiMedium, size: 12))
                
                
                Button("Save") {
                    Task { @MainActor in
                        saveSettings()
                        // Persist settings then close window
                        try? await self.appSettings.save(using: self.storage)
                        NSApplication.shared.keyWindow?.close()
                    }
                }
                .buttonStyle(.vibe(Color(hex: "5B67E2").opacity(0.8)))
            }
        }
        .padding(20)
        .frame(width: 500, height: 400)
        .onAppear {
            loadSettings()
        }
        .task { 
            try? await self.appSettings.save(using: self.storage) 
        }
        .alert("Clear App Session", isPresented: $showingClearSessionAlert) {
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
        refreshFrequency = String(appSettings.overview.refreshInterval)
        usageHistoryLimit = String(appSettings.usageHistory.limit)
        pauseOnScreenSleep = appSettings.pauseOnScreenSleep
        launchAtLogin = launchAtLoginService.isEnabled
        appearanceSelection = appSettings.appearance
    }
    
    private func saveSettings() {
        if let refreshValue = Int(refreshFrequency) {
            appSettings.overview.refreshInterval = refreshValue
        }
        
        if let limitValue = Int(usageHistoryLimit) {
            appSettings.usageHistory.limit = limitValue
        }
        
        appSettings.pauseOnScreenSleep = pauseOnScreenSleep
        
        _ = launchAtLoginService.setEnabled(launchAtLogin)
        appSettings.launchAtLogin = launchAtLogin
        appSettings.appearance = appearanceSelection
    }
    
    private func clearAppSession() async {
        // 清空存储的 AppSession 数据
        await storage.clearAppSession()
        
        // 重置内存中的 AppSession
        session.credentials = nil
        session.snapshot = nil
        
        // 关闭设置窗口
        NSApplication.shared.keyWindow?.close()
    }
}
