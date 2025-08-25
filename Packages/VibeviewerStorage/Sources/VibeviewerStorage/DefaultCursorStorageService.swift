import Foundation
import VibeviewerModel

public enum CursorStorageKeys {
    public static let credentials = "cursor.credentials.v1"
    public static let settings = "app.settings.v1"
    public static let dashboardSnapshot = "cursor.dashboard.snapshot.v1"
}

public struct DefaultCursorStorageService: CursorStorageService, CursorStorageSyncHelpers {
    private let defaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
    }

    // MARK: - Credentials
    public func saveCredentials(_ me: Credentials) async throws {
        let data = try JSONEncoder().encode(me)
        self.defaults.set(data, forKey: CursorStorageKeys.credentials)
    }

    public func loadCredentials() async -> Credentials? {
        guard let data = self.defaults.data(forKey: CursorStorageKeys.credentials) else { return nil }
        return try? JSONDecoder().decode(Credentials.self, from: data)
    }

    public func clearCredentials() async {
        self.defaults.removeObject(forKey: CursorStorageKeys.credentials)
    }

    // MARK: - Dashboard Snapshot
    public func saveDashboardSnapshot(_ snapshot: DashboardSnapshot) async throws {
        let data = try JSONEncoder().encode(snapshot)
        self.defaults.set(data, forKey: CursorStorageKeys.dashboardSnapshot)
    }

    public func loadDashboardSnapshot() async -> DashboardSnapshot? {
        guard let data = self.defaults.data(forKey: CursorStorageKeys.dashboardSnapshot) else { return nil }
        return try? JSONDecoder().decode(DashboardSnapshot.self, from: data)
    }

    public func clearDashboardSnapshot() async {
        self.defaults.removeObject(forKey: CursorStorageKeys.dashboardSnapshot)
    }

    // MARK: - App Settings
    public func saveSettings(_ settings: AppSettings) async throws {
        let data = try JSONEncoder().encode(settings)
        self.defaults.set(data, forKey: CursorStorageKeys.settings)
    }

    public func loadSettings() async -> AppSettings {
        if let data = self.defaults.data(forKey: CursorStorageKeys.settings),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return decoded
        }
        return AppSettings()
    }

    // MARK: - Sync Helpers
    public static func loadCredentialsSync() -> Credentials? {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: CursorStorageKeys.credentials) else { return nil }
        return try? JSONDecoder().decode(Credentials.self, from: data)
    }

    public static func loadDashboardSnapshotSync() -> DashboardSnapshot? {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: CursorStorageKeys.dashboardSnapshot) else { return nil }
        return try? JSONDecoder().decode(DashboardSnapshot.self, from: data)
    }

    public static func loadSettingsSync() -> AppSettings {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: CursorStorageKeys.settings) else { return AppSettings() }
        return (try? JSONDecoder().decode(AppSettings.self, from: data)) ?? AppSettings()
    }
}


