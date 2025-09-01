import Observation
import SwiftUI
import VibeviewerAppEnvironment
import VibeviewerModel
import VibeviewerShareUI

public struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.cursorStorage) private var storage
    @Environment(\.launchAtLoginService) private var launchAtLoginService
    
    @State private var refreshFrequency: String = ""
    @State private var usageHistoryLimit: String = ""
    @State private var pauseOnScreenSleep: Bool = false
    @State private var launchAtLogin: Bool = false
    @State private var appearanceSelection: VibeviewerModel.AppAppearance = .system

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
                
                Button("Cancel") {
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.vibe(Color(hex: "F58283").opacity(0.8)))
                
                Button("Save") {
                    saveSettings()
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.vibe(Color(hex: "5B67E2").opacity(0.8)))
            }
        }
        .padding(20)
        .frame(width: 400, height: 300)
        .onAppear {
            loadSettings()
        }
        .task { 
            try? await self.appSettings.save(using: self.storage) 
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
}
