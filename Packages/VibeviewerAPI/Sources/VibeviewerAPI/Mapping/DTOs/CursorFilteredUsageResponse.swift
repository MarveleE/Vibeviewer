import Foundation

struct CursorFilteredUsageResponse: Decodable, Sendable, Equatable {
    let totalUsageEventsCount: Int
    let usageEventsDisplay: [CursorFilteredUsageEvent]

    init(totalUsageEventsCount: Int, usageEventsDisplay: [CursorFilteredUsageEvent]) {
        self.totalUsageEventsCount = totalUsageEventsCount
        self.usageEventsDisplay = usageEventsDisplay
    }
}


