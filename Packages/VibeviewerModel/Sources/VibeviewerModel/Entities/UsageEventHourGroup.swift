import Foundation
import VibeviewerCore

public struct UsageEventHourGroup: Identifiable, Sendable, Equatable {
    public let id: Date
    public let hourStart: Date
    public let title: String
    public let events: [UsageEvent]

    public var totalRequests: Int { events.map(\.requestCostCount).reduce(0, +) }
    public var totalCostCents: Int { events.map(\.usageCostCents).reduce(0, +) }

    public init(id: Date, hourStart: Date, title: String, events: [UsageEvent]) {
        self.id = id
        self.hourStart = hourStart
        self.title = title
        self.events = events
    }
}

public extension Array where Element == UsageEvent {
    public func groupedByHour(calendar: Calendar = .current) -> [UsageEventHourGroup] {
        var buckets: [Date: [UsageEvent]] = [:]
        for event in self {
            guard let date = DateUtils.date(fromMillisecondsString: event.occurredAtMs),
                  let hourStart = calendar.dateInterval(of: .hour, for: date)?.start else { continue }
            buckets[hourStart, default: []].append(event)
        }

        let sortedStarts = buckets.keys.sorted(by: >)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:00"

        return sortedStarts.map { start in
            UsageEventHourGroup(
                id: start,
                hourStart: start,
                title: formatter.string(from: start),
                events: buckets[start] ?? []
            )
        }
    }
}

public enum UsageEventHourGrouper {
    public static func groupByHour(_ events: [UsageEvent], calendar: Calendar = .current) -> [UsageEventHourGroup] {
        events.groupedByHour(calendar: calendar)
    }
}

public extension UsageEventHourGroup {
    static func group(_ events: [UsageEvent], calendar: Calendar = .current) -> [UsageEventHourGroup] {
        events.groupedByHour(calendar: calendar)
    }
}


