import Foundation
import Testing
import VibeviewerModel
@testable import VibeviewerStorage

@Suite("StorageService basic")
struct StorageServiceTests {
    @Test("Credentials save/load/clear")
    func credentialsCRUD() async throws {
        let suite = UserDefaults(suiteName: "test.credentials.")!
        suite.removePersistentDomain(forName: "test.credentials.")
        let storage = DefaultCursorStorageService(userDefaults: suite)

        let creds = Credentials(userId: 123_456, workosId: "w1", email: "e@x.com", teamId: 1, cookieHeader: "c", isEnterpriseUser: false)
        try await storage.saveCredentials(creds)
        let loaded = await storage.loadCredentials()
        #expect(loaded == creds)
        await storage.clearCredentials()
        let cleared = await storage.loadCredentials()
        #expect(cleared == nil)
    }

    @Test("Snapshot save/load/clear")
    func snapshotCRUD() async throws {
        let suite = UserDefaults(suiteName: "test.snapshot.")!
        suite.removePersistentDomain(forName: "test.snapshot.")
        let storage = DefaultCursorStorageService(userDefaults: suite)

        let snap = DashboardSnapshot(email: "e@x.com", totalRequestsAllModels: 2, spendingCents: 3, hardLimitDollars: 4)
        try await storage.saveDashboardSnapshot(snap)
        let loaded = await storage.loadDashboardSnapshot()
        #expect(loaded == snap)
        await storage.clearDashboardSnapshot()
        let cleared = await storage.loadDashboardSnapshot()
        #expect(cleared == nil)
    }
}
