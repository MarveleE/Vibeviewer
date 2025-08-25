import SwiftUI
import VibeviewerModel

@MainActor
struct DashboardSummaryView: View {
    let snapshot: CursorDashboardSnapshot?

    var body: some View {
        Group {
            if let snapshot {
                VStack(alignment: .leading, spacing: 4) {
                    Text("邮箱: \(snapshot.email)")
                    Text("Plan Requests 已用: \(snapshot.planRequestsUsed)")
                    Text("所有模型总请求: \(snapshot.totalRequestsAllModels)")
                    Text("Usage Spending ($): \(String(format: "%.2f", Double(snapshot.spendingCents) / 100.0))")
                    Text("预算上限 ($): \(snapshot.hardLimitDollars)")
                }
            } else {
                Text("未登录，请先登录 Cursor")
            }
        }
    }
}


