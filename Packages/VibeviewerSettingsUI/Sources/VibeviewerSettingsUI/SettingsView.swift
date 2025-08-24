import SwiftUI
import VibeviewerModel

public struct SettingsView: View {
    @State private var settings: AppSettings = AppSettings()
    @Environment(\.cursorStorage) private var storage

    public init() {}

    public var body: some View {
        Form {
            Section("通用") {
                Toggle("开机自启动", isOn: $settings.launchAtLogin)
                Toggle("显示通知", isOn: $settings.showNotifications)
            }
            Section("网络") {
                Toggle("启用日志", isOn: $settings.enableNetworkLog)
            }
        }
        .padding(16)
        .frame(minWidth: 420, minHeight: 300)
        .task { settings = await storage.loadSettings() }
        .onChange(of: settings) { _, newValue in
            Task { try? await storage.saveSettings(newValue) }
        }
    }
}


