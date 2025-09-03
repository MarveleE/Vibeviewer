import SwiftUI
import VibeviewerModel
import VibeviewerShareUI
import VibeviewerCore

struct UsageEventView: View {
    var events: [UsageEvent]
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        UsageEventViewBody(events: events, limit: appSettings.usageHistory.limit)
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

                Text(event.usageCostDisplay)
                    .font(.app(.satoshiMedium, size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct UsageEventViewBody: View {
    let events: [UsageEvent]
    let limit: Int

    private var groups: [UsageEventHourGroup] {
        Array(events.prefix(limit)).groupedByHour()
    }

    var body: some View {
        UsageEventGroupsView(groups: groups)
    }
}

struct UsageEventGroupsView: View {
    let groups: [UsageEventHourGroup]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(groups) { group in
                HourGroupSectionView(group: group)
            }
        }
    }
}

struct HourGroupSectionView: View {
    let group: UsageEventHourGroup

    var body: some View {
        let totalRequestsText: String = String(group.totalRequests)
        let totalCostText: String = group.totalCostCents.dollarStringFromCents
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(group.title)
                    .font(.app(.satoshiBold, size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 6) {
                    HStack(alignment: .center, spacing: 2) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.app(.satoshiMedium, size: 10))
                            .foregroundStyle(.primary)
                        Text(totalRequestsText)
                            .font(.app(.satoshiMedium, size: 12))
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .center, spacing: 2) {
                        Image(systemName: "dollarsign.circle")
                            .font(.app(.satoshiMedium, size: 10))
                            .foregroundStyle(.primary)
                        Text(totalCostText)
                            .font(.app(.satoshiMedium, size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ForEach(group.events, id: \.occurredAtMs) { event in
                UsageEventView.EventItemView(event: event)
            }
        }
    }
}