import Foundation
import Observation

@Observable
public final class AppSettings: Codable, Sendable, Equatable {
    public var launchAtLogin: Bool
    public var usageHistory: AppSettings.UsageHistory
    public var overview: AppSettings.Overview
    public var pauseOnScreenSleep: Bool
    public var appearance: AppAppearance
    public var analyticsDataDays: Int

    public init(
        launchAtLogin: Bool = false,
        usageHistory: AppSettings.UsageHistory = AppSettings.UsageHistory(limit: 10),
        overview: AppSettings.Overview = AppSettings.Overview(refreshInterval: 5),
        pauseOnScreenSleep: Bool = false,
        appearance: AppAppearance = .system,
        analyticsDataDays: Int = 7
    ) {
        self.launchAtLogin = launchAtLogin
        self.usageHistory = usageHistory
        self.overview = overview
        self.pauseOnScreenSleep = pauseOnScreenSleep
        self.appearance = appearance
        self.analyticsDataDays = analyticsDataDays
    }

    public static func == (lhs: AppSettings, rhs: AppSettings) -> Bool {
        lhs.launchAtLogin == rhs.launchAtLogin &&
            lhs.usageHistory == rhs.usageHistory &&
            lhs.overview == rhs.overview &&
            lhs.pauseOnScreenSleep == rhs.pauseOnScreenSleep &&
            lhs.appearance == rhs.appearance &&
            lhs.analyticsDataDays == rhs.analyticsDataDays
    }

    // MARK: - Codable (backward compatible)

    private enum CodingKeys: String, CodingKey {
        case launchAtLogin
        case usageHistory
        case overview
        case pauseOnScreenSleep
        case appearance
        case analyticsDataDays
    }

    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        let usageHistory = try container.decodeIfPresent(AppSettings.UsageHistory.self, forKey: .usageHistory) ?? AppSettings.UsageHistory(limit: 10)
        let overview = try container.decodeIfPresent(AppSettings.Overview.self, forKey: .overview) ?? AppSettings.Overview(refreshInterval: 5)
        let pauseOnScreenSleep = try container.decodeIfPresent(Bool.self, forKey: .pauseOnScreenSleep) ?? false
        let appearance = try container.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system
        let analyticsDataDays = try container.decodeIfPresent(Int.self, forKey: .analyticsDataDays) ?? 7
        self.init(
            launchAtLogin: launchAtLogin,
            usageHistory: usageHistory,
            overview: overview,
            pauseOnScreenSleep: pauseOnScreenSleep,
            appearance: appearance,
            analyticsDataDays: analyticsDataDays
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.launchAtLogin, forKey: .launchAtLogin)
        try container.encode(self.usageHistory, forKey: .usageHistory)
        try container.encode(self.overview, forKey: .overview)
        try container.encode(self.pauseOnScreenSleep, forKey: .pauseOnScreenSleep)
        try container.encode(self.appearance, forKey: .appearance)
        try container.encode(self.analyticsDataDays, forKey: .analyticsDataDays)
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

    // moved to its own file: AppAppearance
}
