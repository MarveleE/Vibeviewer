import SwiftUI
import VibeviewerAPI
import VibeviewerAppEnvironment
import VibeviewerLoginUI
import VibeviewerModel
import VibeviewerSettingsUI

@MainActor
public struct MenuPopoverView: View {
    @Environment(\.cursorService) private var service
    @Environment(\.cursorStorage) private var storage
    @Environment(\.loginWindowManager) private var loginWindow
    @Environment(\.settingsWindowManager) private var settingsWindow

    @State private var credentials: CursorCredentials?
    @State private var snapshot: CursorDashboardSnapshot?
    @State private var isLoading: Bool = false
    @State private var lastErrorMessage: String?
    @State private var refreshTask: Task<Void, Never>?

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let snapshot {
                Text("邮箱: \(snapshot.email)")
                Text("Plan Requests 已用: \(snapshot.planRequestsUsed)")
                Text("所有模型总请求: \(snapshot.totalRequestsAllModels)")
                Text("Usage Spending ($): \(String(format: "%.2f", Double(snapshot.spendingCents) / 100.0))")
                Text("预算上限 ($): \(snapshot.hardLimitDollars)")
            } else {
                Text("未登录，请先登录 Cursor")
            }

            if let msg = lastErrorMessage, !msg.isEmpty {
                Text(msg).foregroundStyle(.red).font(.caption)
            }

            HStack(spacing: 10) {
                if self.isLoading {
                    ProgressView()
                } else {
                    Button("刷新") { Task { await self.refresh() } }
                }

                if self.credentials == nil {
                    Button("登录") {
                        self.loginWindow.show { cookie in
                            Task { await self.completeLogin(cookieHeader: cookie) }
                        }
                    }
                } else {
                    Button("退出登录") { Task { await self.setLoggedOut() } }
                }
                Button("设置") { self.settingsWindow.show() }
            }
        }
        .padding(16)
        .frame(minWidth: 320)
        .task { await self.loadInitial() }
    }

    private func loadInitial() async {
        self.credentials = await self.storage.loadCredentials()
        if self.credentials != nil {
            await self.refresh()
            self.startAutoRefresh()
        }
    }

    private func startAutoRefresh() {
        self.refreshTask?.cancel()
        self.refreshTask = Task {
            while !Task.isCancelled {
                await self.refresh()
                try? await Task.sleep(for: .seconds(5 * 60))
            }
        }
    }

    private func setLoggedOut() async {
        await self.storage.clearCredentials()
        self.credentials = nil
        self.snapshot = nil
        self.refreshTask?.cancel()
        self.refreshTask = nil
    }

    private func completeLogin(cookieHeader: String) async {
        self.isLoading = true
        self.lastErrorMessage = nil
        do {
            let me = try await service.fetchMe(cookieHeader: cookieHeader)
            let usage = try await service.fetchUsage(workosUserId: me.workosId, cookieHeader: cookieHeader)
            let spend = try await service.fetchTeamSpend(teamId: me.teamId, cookieHeader: cookieHeader)

            let planRequestsUsed = usage.models.values.map(\.numRequests).reduce(0, +)
            let totalAll = usage.models.values.map(\.numRequestsTotal).reduce(0, +)
            let mySpend = spend.teamMemberSpend.first { $0.userId == me.userId }
            let newSnapshot = CursorDashboardSnapshot(
                email: me.email,
                planRequestsUsed: planRequestsUsed,
                totalRequestsAllModels: totalAll,
                spendingCents: mySpend?.spendCents ?? 0,
                hardLimitDollars: mySpend?.hardLimitOverrideDollars ?? 0
            )

            let creds = CursorCredentials(
                userId: me.userId,
                workosId: me.workosId,
                email: me.email,
                teamId: me.teamId,
                cookieHeader: cookieHeader
            )
            try await self.storage.saveCredentials(creds)
            self.credentials = creds
            self.snapshot = newSnapshot
            self.startAutoRefresh()
        } catch {
            self.lastErrorMessage = error.localizedDescription
        }
        self.isLoading = false
    }

    private func refresh() async {
        guard let creds = credentials else { return }
        self.isLoading = true
        self.lastErrorMessage = nil
        do {
            let usage = try await service.fetchUsage(workosUserId: creds.workosId, cookieHeader: creds.cookieHeader)
            let spend = try await service.fetchTeamSpend(teamId: creds.teamId, cookieHeader: creds.cookieHeader)
            let planRequestsUsed = usage.models.values.map(\.numRequests).reduce(0, +)
            let totalAll = usage.models.values.map(\.numRequestsTotal).reduce(0, +)
            let mySpend = spend.teamMemberSpend.first { $0.userId == creds.userId }
            self.snapshot = CursorDashboardSnapshot(
                email: creds.email,
                planRequestsUsed: planRequestsUsed,
                totalRequestsAllModels: totalAll,
                spendingCents: mySpend?.spendCents ?? 0,
                hardLimitDollars: mySpend?.hardLimitOverrideDollars ?? 0
            )
        } catch {
            if case CursorServiceError.sessionExpired = error {
                await self.setLoggedOut()
                self.lastErrorMessage = "会话已过期，请重新登录"
            } else {
                self.lastErrorMessage = error.localizedDescription
            }
        }
        self.isLoading = false
    }
}
