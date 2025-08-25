import Foundation

public struct FilteredUsageHistory: Sendable, Equatable {
    public let totalCount: Int
    public let events: [UsageEvent]

    public init(totalCount: Int, events: [UsageEvent]) {
        self.totalCount = totalCount
        self.events = events
    }
}
