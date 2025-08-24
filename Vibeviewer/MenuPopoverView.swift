import SwiftUI
import Observation

@MainActor
struct MenuPopoverView: View {
    @State var model: CursorDataModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let snapshot = model.snapshot {
                Text("邮箱: \(snapshot.email)")
                Text("Plan Requests 已用: \(snapshot.planRequestsUsed)")
                Text("所有模型总请求: \(snapshot.totalRequestsAllModels)")
                Text("Usage Spending ($): \(String(format: "%.2f", Double(snapshot.spendingCents) / 100.0))")
                Text("预算上限 ($): \(snapshot.hardLimitDollars)")
            } else {
                Text("未登录，请先登录 Cursor")
            }

            if let msg = model.lastErrorMessage, !msg.isEmpty {
                Text(msg).foregroundStyle(.red).font(.caption)
            }

            HStack(spacing: 10) {
                if model.isLoading {
                    ProgressView()
                } else {
                    Button("刷新") { Task { await model.refresh() } }
                }

                if model.credentials == nil {
                    Button("登录") {
                        LoginWindowManager.shared.show { cookie in
                            Task { await model.completeLogin(cookieHeader: cookie) }
                        }
                    }
                } else {
                    Button("退出登录") { Task { await model.setLoggedOut() } }
                }
            }
        }
        .padding(16)
        .frame(minWidth: 320)
    }
}



