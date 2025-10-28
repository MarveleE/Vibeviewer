import Foundation

struct CursorFilteredUsageResponse: Decodable, Sendable, Equatable {
    let totalUsageEventsCount: Int?
    let usageEventsDisplay: [CursorFilteredUsageEvent]?

    init(totalUsageEventsCount: Int? = nil, usageEventsDisplay: [CursorFilteredUsageEvent]? = nil) {
        self.totalUsageEventsCount = totalUsageEventsCount
        self.usageEventsDisplay = usageEventsDisplay
    }
}
