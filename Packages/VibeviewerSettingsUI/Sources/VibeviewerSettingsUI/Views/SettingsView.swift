import SwiftUI
import VibeviewerAppEnvironment
import VibeviewerModel

public struct SettingsView: View {
    @State private var settings: AppSettings = .init()
    @Environment(\.cursorStorage) private var storage

    public init() {}

    public var body: some View {
        Form {
            Section("通用") {
                Toggle("开机自启动", isOn: self.$settings.launchAtLogin)
                Toggle("显示通知", isOn: self.$settings.showNotifications)
            }
            Section("网络") {
                Toggle("启用日志", isOn: self.$settings.enableNetworkLog)
            }
        }
        .padding(16)
        .frame(minWidth: 420, minHeight: 300)
        .task { self.settings = await self.storage.loadSettings() }
        .onChange(of: self.settings) { _, newValue in
            Task { try? await self.storage.saveSettings(newValue) }
        }
    }
}
