import Foundation

public enum CursorStorageKeys {
    public static let credentials = "cursor.credentials.v1"
    public static let settings = "app.settings.v1"
    public static let dashboardSnapshot = "cursor.dashboard.snapshot.v1"
}

public actor CursorStorage {
    public static let shared = CursorStorage()

    private let defaults = UserDefaults.standard

    public func saveCredentials(_ creds: Credentials) async throws {
        let data = try JSONEncoder().encode(creds)
        self.defaults.set(data, forKey: CursorStorageKeys.credentials)
    }

    public func loadCredentials() async -> Credentials? {
        guard let data = defaults.data(forKey: CursorStorageKeys.credentials) else { return nil }
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
        guard let data = defaults.data(forKey: CursorStorageKeys.dashboardSnapshot) else { return nil }
        return try? JSONDecoder().decode(DashboardSnapshot.self, from: data)
    }

    public func clearDashboardSnapshot() async {
        self.defaults.removeObject(forKey: CursorStorageKeys.dashboardSnapshot)
    }

    // MARK: - Synchronous preload helpers (for app launch)

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
}
