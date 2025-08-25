import Foundation
import VibeviewerModel

public extension AppSettings {
    func save(using storage: any CursorStorageService) async throws {
        try await storage.saveSettings(self)
    }
}
