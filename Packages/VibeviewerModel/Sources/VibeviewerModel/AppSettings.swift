import Foundation

public struct AppSettings: Codable, Sendable, Equatable {
    public var launchAtLogin: Bool
    public var showNotifications: Bool
    public var enableNetworkLog: Bool

    public init(
        launchAtLogin: Bool = false,
        showNotifications: Bool = true,
        enableNetworkLog: Bool = true
    ) {
        self.launchAtLogin = launchAtLogin
        self.showNotifications = showNotifications
        self.enableNetworkLog = enableNetworkLog
    }
}

public extension CursorStorage {
    func saveSettings(_ settings: AppSettings) async throws {
        let data = try JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: CursorStorageKeys.settings)
    }

    func loadSettings() async -> AppSettings {
        if let data = UserDefaults.standard.data(forKey: CursorStorageKeys.settings),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return decoded
        }
        return AppSettings()
    }
}


