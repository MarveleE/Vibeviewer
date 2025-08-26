import SwiftUI
import VibeviewerModel
import VibeviewerShareUI

struct MetricsViewDataSource: Equatable { 
    var icon: String
    var title: String
    var description: String?
    var currentValue: String
    var targetValue: String
    var progress: Double
    var tint: Color
}

struct MetricsView: View {
    enum MetricType {
        case billing(MetricsViewDataSource)
        case planRequests(MetricsViewDataSource)
    }

    var metric: MetricType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch metric {
            case .billing(let dataSource):
                MetricContentView(dataSource: dataSource)
            case .planRequests(let dataSource):
                MetricContentView(dataSource: dataSource)
            }
        }
    }

    struct MetricContentView: View {
        let dataSource: MetricsViewDataSource

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: dataSource.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(dataSource.tint)
                        Text(dataSource.title)
                            .font(.app(.satoshiBold, size: 12))
                            .foregroundStyle(dataSource.tint)
                    }

                    Spacer()

                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        Text(dataSource.currentValue)
                            .font(.app(.satoshiBold, size: 16))
                            .foregroundStyle(.primary)

                        Text(" / ")
                            .font(.app(.satoshiRegular, size: 12))
                            .foregroundStyle(.secondary)

                        Text(dataSource.targetValue)
                            .font(.app(.satoshiRegular, size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                progressBar(color: dataSource.tint)

                if let description = dataSource.description {
                    Text(description)
                        .font(.app(.satoshiRegular, size: 10))
                        .foregroundStyle(.secondary)
                }
            }
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
    var billingMetrics: MetricsViewDataSource {
        MetricsViewDataSource(
            icon: "dollarsign.circle.fill",
            title: "Usage Spending",
            description: "Your current spending",
            currentValue: spendingCents.dollarStringFromCents,
            targetValue: (hardLimitDollars * 100).dollarStringFromCents,
            progress: min(Double(spendingCents) / Double(hardLimitDollars * 100), 1),
            tint: Color(hex: "55E07A").opacity(0.5)
        )
    }

    var planRequestsMetrics: MetricsViewDataSource {
        MetricsViewDataSource(
            icon: "calendar.circle.fill",
            title: "Total Requests",
            description: "Your current plan requests",
            currentValue: "\(totalRequestsAllModels)",
            targetValue: "\(planIncludeRequestCount)",
            progress: min(Double(planRequestsUsed) / Double(planIncludeRequestCount), 1),
            tint: Color(hex: "559DE0").opacity(0.5)
        )
    }
}