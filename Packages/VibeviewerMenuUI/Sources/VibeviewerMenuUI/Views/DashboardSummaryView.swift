import SwiftUI
import VibeviewerCore
import VibeviewerModel

@MainActor
struct DashboardSummaryView: View {
    let snapshot: DashboardSnapshot?

    var body: some View {
        Group {
            if let snapshot {
                VStack(alignment: .leading, spacing: 4) {
                    Text("邮箱: \(snapshot.email)")
                    Text("所有模型总请求: \(snapshot.totalRequestsAllModels)")
                    Text("Usage Spending ($): \(snapshot.spendingCents.dollarStringFromCents)")
                    Text("预算上限 ($): \(snapshot.hardLimitDollars)")
                    
                    if let usageSummary = snapshot.usageSummary {
                        Text("Plan Usage: \(usageSummary.individualUsage.plan.used)/\(usageSummary.individualUsage.plan.limit)")
                        if let onDemand = usageSummary.individualUsage.onDemand,
                           let limit = onDemand.limit {
                            Text("On-Demand Usage: \(onDemand.used)/\(limit)")
                        }
                    }
                }
            } else {
                Text("未登录，请先登录 Cursor")
            }
        }
    }
}
