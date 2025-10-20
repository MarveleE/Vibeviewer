import SwiftUI
import VibeviewerModel
import VibeviewerCore
import VibeviewerShareUI
import Foundation

struct MetricsViewDataSource: Equatable { 
    var icon: String
    var title: String
    var description: String?
    var currentValue: String
    var targetValue: String?
    var progress: Double
    var tint: Color
}

struct MetricsView: View {
    enum MetricType {
        case billing(MetricsViewDataSource)
        case onDemand(MetricsViewDataSource)
            case free(MetricsViewDataSource)
    }

    var metric: MetricType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch metric {
            case .billing(let dataSource):
                MetricContentView(dataSource: dataSource)
            case .onDemand(let dataSource):
                MetricContentView(dataSource: dataSource)
            case .free(let dataSource):
                MetricContentView(dataSource: dataSource)
            }
        }
    }

    struct MetricContentView: View {
        let dataSource: MetricsViewDataSource

        @State var isHovering: Bool = false

        @Environment(\.colorScheme) private var colorScheme

        var tintColor: Color {
            if isHovering {
                return dataSource.tint
            } else {
                return dataSource.tint.opacity(colorScheme == .dark ? 0.5 : 0.8)
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: dataSource.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(tintColor)
                        Text(dataSource.title)
                            .font(.app(.satoshiBold, size: 12))
                            .foregroundStyle(tintColor)
                    }

                    Spacer()

                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        if let target = dataSource.targetValue, !target.isEmpty {
                            Text(target)
                                .font(.app(.satoshiRegular, size: 12))
                                .foregroundStyle(.secondary)

                            Text(" / ")
                                .font(.app(.satoshiRegular, size: 12))
                                .foregroundStyle(.secondary)

                            Text(dataSource.currentValue)
                                .font(.app(.satoshiBold, size: 16))
                                .foregroundStyle(.primary)
                                .contentTransition(.numericText())
                        } else {
                            Text(dataSource.currentValue)
                                .font(.app(.satoshiBold, size: 16))
                                .foregroundStyle(.primary)
                                .contentTransition(.numericText())
                        }
                    }
                }

                progressBar(color: tintColor)

                if let description = dataSource.description {
                    Text(description)
                        .font(.app(.satoshiRegular, size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .onHover { isHovering = $0 }
        }

        @ViewBuilder
        func progressBar(color: Color) -> some View {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color(hex: "686868").opacity(0.5))
                    .frame(height: 4)

                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 100)
                        .fill(color)
                        .frame(width: proxy.size.width * dataSource.progress, height: 4)
                }
                .frame(height: 4)
            }
        }
    }
}

extension DashboardSnapshot {
    // MARK: - Subscription Expiry Configuration
    
    /// Configuration for subscription expiry date calculation
    /// Modify this enum to change expiry date behavior with minimal code changes
    private enum SubscriptionExpiryRule {
        case endOfCurrentMonth
        case specificDaysFromNow(Int)
        case endOfNextMonth
        // Add more cases as needed
    }
    
    /// Current expiry rule - change this to modify expiry date calculation
    private var currentExpiryRule: SubscriptionExpiryRule {
        .endOfCurrentMonth // Can be easily changed to any other rule
    }
    
    // MARK: - Helper Properties for Expiry Date Calculation
    
    /// Current subscription expiry date based on configured rule
    private var subscriptionExpiryDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch currentExpiryRule {
        case .endOfCurrentMonth:
            let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
            return calendar.date(byAdding: .day, value: -1, to: endOfMonth) ?? now
            
        case .specificDaysFromNow(let days):
            return calendar.date(byAdding: .day, value: days, to: now) ?? now
            
        case .endOfNextMonth:
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) ?? now
            let endOfNextMonth = calendar.dateInterval(of: .month, for: nextMonth)?.end ?? now
            return calendar.date(byAdding: .day, value: -1, to: endOfNextMonth) ?? now
        }
    }
    
    /// Formatted expiry date string in yy:mm:dd format
    private var expiryDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy:MM:dd"
        return formatter.string(from: subscriptionExpiryDate)
    }
    
    /// Remaining days until subscription expiry
    private var remainingDays: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: subscriptionExpiryDate).day ?? 0
        return max(days, 1) // At least 1 day to avoid division by zero
    }
    
    /// Remaining balance in cents
    private var remainingBalanceCents: Int {
        return max((hardLimitDollars * 100) - spendingCents, 0)
    }
    
    /// Average daily spending allowance from remaining balance
    private var averageDailyAllowance: String {
        let dailyAllowanceCents = remainingBalanceCents / remainingDays
        return dailyAllowanceCents.dollarStringFromCents
    }
    
    var billingMetrics: MetricsViewDataSource {
        // 如果有新的usageSummary数据，优先使用
        if let usageSummary = usageSummary {
            let description = "Expires \(expiryDateString)"
            
            // UsageSummary 的 used/limit 已经是美分，直接转换为美元显示
            return MetricsViewDataSource(
                icon: "dollarsign.circle.fill",
                title: "Plan Usage",
                description: description,
                currentValue: usageSummary.individualUsage.plan.used.dollarStringFromCents,
                targetValue: usageSummary.individualUsage.plan.limit.dollarStringFromCents,
                progress: min(Double(usageSummary.individualUsage.plan.used) / Double(usageSummary.individualUsage.plan.limit), 1),
                tint: Color(hex: "55E07A")
            )
        } else {
            // 回退到旧的数据源
            let description = "Expires \(expiryDateString), \(averageDailyAllowance)/day remaining"
            
            return MetricsViewDataSource(
                icon: "dollarsign.circle.fill",
                title: "Usage Spending",
                description: description,
                currentValue: spendingCents.dollarStringFromCents,
                targetValue: (hardLimitDollars * 100).dollarStringFromCents,
                progress: min(Double(spendingCents) / Double(hardLimitDollars * 100), 1),
                tint: Color(hex: "55E07A")
            )
        }
    }

    var onDemandMetrics: MetricsViewDataSource? {
        guard let usageSummary = usageSummary,
              let onDemand = usageSummary.individualUsage.onDemand else {
            return nil
        }
        
        let description = "Expires \(expiryDateString)"
        
        // UsageSummary 的 used/limit 已经是美分，直接转换为美元显示
        return MetricsViewDataSource(
            icon: "bolt.circle.fill",
            title: "On-Demand Usage",
            description: description,
            currentValue: onDemand.used.dollarStringFromCents,
            targetValue: onDemand.limit.dollarStringFromCents,
            progress: min(Double(onDemand.used) / Double(onDemand.limit), 1),
            tint: Color(hex: "FF6B6B")
        )
    }

    var freeUsageMetrics: MetricsViewDataSource? {
        guard freeUsageCents > 0 else { return nil }
        let description = "Free credits (team plan)"
        return MetricsViewDataSource(
            icon: "gift.circle.fill",
            title: "Free Usage",
            description: description,
            currentValue: freeUsageCents.dollarStringFromCents,
            targetValue: nil,
            progress: 0,
            tint: Color(hex: "4DA3FF")
        )
    }
}