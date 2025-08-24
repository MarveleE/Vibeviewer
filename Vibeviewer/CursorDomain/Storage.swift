import Foundation

enum CursorStorageKeys {
    static let credentials = "cursor.credentials.v1"
}

actor CursorStorage {
    static let shared = CursorStorage()

    private let defaults = UserDefaults.standard

    func saveCredentials(_ creds: CursorCredentials) async throws {
        let data = try JSONEncoder().encode(creds)
        defaults.set(data, forKey: CursorStorageKeys.credentials)
    }

    func loadCredentials() async -> CursorCredentials? {
        guard let data = defaults.data(forKey: CursorStorageKeys.credentials) else { return nil }
        return try? JSONDecoder().decode(CursorCredentials.self, from: data)
    }

    func clearCredentials() async {
        defaults.removeObject(forKey: CursorStorageKeys.credentials)
    }
}


