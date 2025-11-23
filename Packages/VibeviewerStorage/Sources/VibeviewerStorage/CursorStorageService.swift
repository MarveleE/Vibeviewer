import Foundation
import VibeviewerModel

// Service Protocol (exposed)
public protocol CursorStorageService: Sendable {
    // Credentials
    func saveCredentials(_ creds: Credentials) async throws
    func loadCredentials() async -> Credentials?
    func clearCredentials() async

    // Dashboard Snapshot
    func saveDashboardSnapshot(_ snapshot: DashboardSnapshot) async throws
    func loadDashboardSnapshot() async -> DashboardSnapshot?
    func clearDashboardSnapshot() async

    // App Settings
    func saveSettings(_ settings: AppSettings) async throws
    func loadSettings() async -> AppSettings
    
    // Billing Cycle
    func saveBillingCycle(startDateMs: String, endDateMs: String) async throws
    func loadBillingCycle() async -> (startDateMs: String, endDateMs: String)?
    func clearBillingCycle() async
    
    // AppSession Management
    func clearAppSession() async
}

// Synchronous preload helpers for app launch use-cases
public protocol CursorStorageSyncHelpers {
    static func loadCredentialsSync() -> Credentials?
    static func loadDashboardSnapshotSync() -> DashboardSnapshot?
    static func loadSettingsSync() -> AppSettings
}
