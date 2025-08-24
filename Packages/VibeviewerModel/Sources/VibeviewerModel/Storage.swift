import Foundation

public enum CursorStorageKeys {
    public static let credentials = "cursor.credentials.v1"
}

public actor CursorStorage {
    public static let shared = CursorStorage()

    private let defaults = UserDefaults.standard

    public func saveCredentials(_ creds: CursorCredentials) async throws {
        let data = try JSONEncoder().encode(creds)
        defaults.set(data, forKey: CursorStorageKeys.credentials)
    }

    public func loadCredentials() async -> CursorCredentials? {
        guard let data = defaults.data(forKey: CursorStorageKeys.credentials) else { return nil }
        return try? JSONDecoder().decode(CursorCredentials.self, from: data)
    }

    public func clearCredentials() async {
        defaults.removeObject(forKey: CursorStorageKeys.credentials)
    }
}


