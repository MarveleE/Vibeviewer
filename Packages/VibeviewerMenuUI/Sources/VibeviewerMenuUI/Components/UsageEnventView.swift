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
        @State private var isExpanded = false

        // MARK: - Body

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                mainRowView

                if isExpanded {
                    expandedDetailsView
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        // MARK: - Computed Properties

        private var totalTokensDisplay: String {
            let totalTokens = event.tokenUsage?.totalTokens ?? 0
            let tokensInWan = Double(totalTokens) / 10000.0
            return String(format: "%.1fM", tokensInWan)
        }

        private var costDisplay: String {
            let totalCents = (event.tokenUsage?.totalCents ?? 0.0) + event.cursorTokenFee
            let dollars = totalCents / 100.0
            return String(format: "$%.2f", dollars)
        }

        private var tokenDetails: [(label: String, value: Int)] {
            let rawDetails: [(String, Int)] = [
                ("Input", event.tokenUsage?.inputTokens ?? 0),
                ("Output", event.tokenUsage?.outputTokens ?? 0),
                ("Cache Write", event.tokenUsage?.cacheWriteTokens ?? 0),
                ("Cache Read", event.tokenUsage?.cacheReadTokens ?? 0),
                ("Total Tokens", event.tokenUsage?.totalTokens ?? 0),
            ]
            return rawDetails
        }

        // MARK: - Subviews

        private var brandLogoView: some View {
            event.brand.logo
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .padding(6)
                .background(.thinMaterial, in: .circle)
        }

        private var modelNameView: some View {
            Text(event.modelName)
                .font(.app(.satoshiBold, size: 14))
                .lineLimit(1)
                // .foregroundStyle(event.kind.isError ? AnyShapeStyle(Color.red.secondary) : AnyShapeStyle(.primary))
        }

        private var tokenCostView: some View {
            HStack(spacing: 12) {
                Text(totalTokensDisplay)
                    .font(.app(.satoshiMedium, size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Text(costDisplay)
                    .font(.app(.satoshiMedium, size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .layoutPriority(1)
        }

        private var mainRowView: some View {
            HStack(spacing: 12) {
                brandLogoView
                modelNameView
                Spacer()
                tokenCostView
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
            }
        }

        private func tokenDetailRowView(for detail: (String, Int)) -> some View {
            HStack {
                Text(detail.0)
                    .font(.app(.satoshiRegular, size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .leading)

                Spacer()

                Text("\(detail.1)")
                    .font(.app(.satoshiMedium, size: 12))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

            }
            .padding(.horizontal, 12)
        }

        private var expandedDetailsView: some View {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(tokenDetails, id: \.0) { detail in
                    tokenDetailRowView(for: detail)
                }
            }
            .padding(.vertical, 4)
            .transition(.opacity)
            .fixedSize(horizontal: false, vertical: true)
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
        let totalCostText: String = {
            let totalCents = group.events.reduce(0.0) { sum, event in
                sum + (event.tokenUsage?.totalCents ?? 0.0) + event.cursorTokenFee
            }
            let dollars = totalCents / 100.0
            return String(format: "$%.2f", dollars)
        }()
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
