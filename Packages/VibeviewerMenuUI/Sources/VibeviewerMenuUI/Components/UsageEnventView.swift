import SwiftUI
import VibeviewerModel
import VibeviewerShareUI
import VibeviewerCore

struct UsageEventView: View {
    var events: [UsageEvent]
    @Environment(AppSettings.self) private var appSettings
    
    struct HourGroup: Identifiable, Equatable {
        let id: Date
        let hourStart: Date
        let title: String
        let events: [UsageEvent]

        var totalRequests: Int {
            events.reduce(0) { $0 + $1.requestCostCount }
        }

        var totalCostDollars: Double {
            events.reduce(0.0) { partial, e in
                partial + Self.parseDollarString(e.usageCostDisplay)
            }
        }

        var totalCostDisplay: String {
            String(format: "$%.2f", totalCostDollars)
        }

        private static func parseDollarString(_ s: String) -> Double {
            // Expect format like "$0.04"; fallback to 0 for invalid
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let idx = trimmed.firstIndex(where: { ($0 >= "0" && $0 <= "9") || $0 == "." }) else { return 0 }
            let numberPart = trimmed[idx...]
            return Double(numberPart) ?? 0
        }

        static func group(events: [UsageEvent], calendar: Calendar = .current) -> [HourGroup] {
            var buckets: [Date: [UsageEvent]] = [:]
            for event in events {
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
                HourGroup(
                    id: start,
                    hourStart: start,
                    title: formatter.string(from: start),
                    events: buckets[start] ?? []
                )
            }
        }
    }

    private var limitedEvents: [UsageEvent] {
        Array(events.prefix(appSettings.usageHistory.limit))
    }

    private var hourlyGroups: [HourGroup] {
        HourGroup.group(events: limitedEvents)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(hourlyGroups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(group.title)
                            .font(.app(.satoshiBold, size: 12))
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 10) {
                            Text("req: \(group.totalRequests)")
                            Text("cost: \(group.totalCostDisplay)")
                        }
                        .font(.app(.satoshiMedium, size: 12))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 2)

                    ForEach(group.events, id: \.occurredAtMs) { event in
                        EventItemView(event: event)
                    }
                }
            }
        }
        .contentShape(.rect)
    }

    struct EventItemView: View {
        let event: UsageEvent

        var body: some View {
            HStack(spacing: 12) {
                event.brand.logo
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .padding(6)
                    .background(.thinMaterial, in: .circle)

                Text(event.modelName)
                    .font(.app(.satoshiBold, size: 14))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(event.usageCostDisplay)")
                    .font(.app(.satoshiMedium, size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}