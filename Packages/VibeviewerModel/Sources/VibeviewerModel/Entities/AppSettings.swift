import Foundation
import Observation

@Observable
public final class AppSettings: Codable, Sendable, Equatable {
    public var launchAtLogin: Bool
    public var usageHistory: AppSettings.UsageHistory
    public var overview: AppSettings.Overview
    public var pauseOnScreenSleep: Bool

    public init(
        launchAtLogin: Bool = false,
        usageHistory: AppSettings.UsageHistory = AppSettings.UsageHistory(limit: 10),
        overview: AppSettings.Overview = AppSettings.Overview(refreshInterval: 5),
        pauseOnScreenSleep: Bool = false
    ) {
        self.launchAtLogin = launchAtLogin
        self.usageHistory = usageHistory
        self.overview = overview
        self.pauseOnScreenSleep = pauseOnScreenSleep
    }

    public static func == (lhs: AppSettings, rhs: AppSettings) -> Bool {
        lhs.launchAtLogin == rhs.launchAtLogin &&
            lhs.usageHistory == rhs.usageHistory &&
            lhs.overview == rhs.overview &&
            lhs.pauseOnScreenSleep == rhs.pauseOnScreenSleep
    }

    public struct Overview: Codable, Sendable, Equatable {
        public var refreshInterval: Int

        public init(
            refreshInterval: Int = 5
        ) {
            self.refreshInterval = refreshInterval
        }
    }

    public struct UsageHistory: Codable, Sendable, Equatable {
        public var limit: Int

        public init(
            limit: Int = 10
        ) {
            self.limit = limit
        }
    }
}
