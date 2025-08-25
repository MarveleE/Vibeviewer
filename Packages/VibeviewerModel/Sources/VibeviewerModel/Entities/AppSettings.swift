import Foundation
import Observation

@Observable
public final class AppSettings: Codable, Sendable, Equatable {
    public var launchAtLogin: Bool
    public var usageHistory: AppSettings.UsageHistory
    public var overview: AppSettings.Overview

    public init(
        launchAtLogin: Bool = false,
        usageHistory: AppSettings.UsageHistory = AppSettings.UsageHistory(limit: 5),
        overview: AppSettings.Overview = AppSettings.Overview(refreshInterval: 5)
    ) {
        self.launchAtLogin = launchAtLogin
        self.usageHistory = usageHistory
        self.overview = overview
    }

    public static func == (lhs: AppSettings, rhs: AppSettings) -> Bool {
        lhs.launchAtLogin == rhs.launchAtLogin &&
        lhs.usageHistory == rhs.usageHistory &&
        lhs.overview == rhs.overview
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
        public var show: Bool
        public var dateRange: DateRange
        public var limit: Int
        public var refreshInterval: Int

        public init(
            show: Bool = false,
            dateRange: DateRange = DateRange(start: Date(), end: Date()),
            limit: Int = 10,
            refreshInterval: Int = 10
        ) {
            self.show = show
            self.dateRange = dateRange
            self.limit = limit
            self.refreshInterval = refreshInterval
        }

        public struct DateRange: Codable, Sendable, Equatable {
            public var start: Date
            public var end: Date

            public init(
                start: Date = Date(),
                end: Date = Date()
            ) {
                self.start = start
                self.end = end
            }
        }
    }
}
