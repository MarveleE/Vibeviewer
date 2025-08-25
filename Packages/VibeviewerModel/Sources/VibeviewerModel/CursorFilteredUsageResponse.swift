import Foundation

public struct CursorFilteredUsageResponse: Decodable, Sendable, Equatable {
    public let totalUsageEventsCount: Int
    public let usageEventsDisplay: [CursorFilteredUsageEvent]

    public init(totalUsageEventsCount: Int, usageEventsDisplay: [CursorFilteredUsageEvent]) {
        self.totalUsageEventsCount = totalUsageEventsCount
        self.usageEventsDisplay = usageEventsDisplay
    }
}


