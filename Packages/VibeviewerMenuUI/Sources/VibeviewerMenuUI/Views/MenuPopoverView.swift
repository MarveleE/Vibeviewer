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
    @Environment(\.appSettings) private var settings

    @State private var credentials: Credentials?
    @State private var snapshot: DashboardSnapshot?
    @State private var isLoading: Bool = false
    @State private var lastErrorMessage: String?
    @State private var refreshTask: Task<Void, Never>?

    // Usage History (filtered by date)
    @State private var selectedDate: Date = Date()
    @State private var historyLimit: Int = 10
    @State private var usageEvents: [VibeviewerModel.UsageEvent] = []
    @State private var isLoadingHistory: Bool = false

    public init(initialCredentials: Credentials? = nil, initialSnapshot: DashboardSnapshot? = nil) {
        self._credentials = State(initialValue: initialCredentials)
        self._snapshot = State(initialValue: initialSnapshot)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSummaryView(snapshot: snapshot)

            ErrorBannerView(message: lastErrorMessage)

            ActionButtonsView(
                isLoading: isLoading,
                isLoggedIn: credentials != nil,
                onRefresh: { Task { await self.refresh() } },
                onLogin: {
                    self.loginWindow.show { cookie in
                        Task { await self.completeLogin(cookieHeader: cookie) }
                    }
                },
                onLogout: { Task { await self.setLoggedOut() } },
                onSettings: { self.settingsWindow.show() }
            )

            UsageHistorySection(
                isLoading: isLoadingHistory,
                selectedDate: $selectedDate,
                historyLimit: $historyLimit,
                events: usageEvents,
                onReload: { Task { await fetchUsageHistory() } },
                onToday: { selectedDate = Date() }
            )
        }
        .padding(16)
        .frame(minWidth: 320)
        .task { await self.loadInitial() }
        .onChange(of: selectedDate) { _, _ in Task { await fetchUsageHistory() } }
        .onChange(of: historyLimit) { _, _ in Task { await fetchUsageHistory() } }
    }

    private func loadInitial() async {
        // 先从本地读取最近一次的快照，避免冷启动空白
        if let cached = await self.storage.loadDashboardSnapshot() {
            self.snapshot = cached
        }

        // 读取登录态
        self.credentials = await self.storage.loadCredentials()
        if self.credentials != nil {
            // 登录态存在则进行一次刷新以获得最新数据
            await self.refresh()
            self.startAutoRefresh()
            await self.fetchUsageHistory()
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
        await self.storage.clearDashboardSnapshot()
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

            let planRequestsUsed = usage.models.values.map(\.requestsUsed).reduce(0, +)
            let totalAll = usage.models.values.map(\.totalRequests).reduce(0, +)
            let mySpend = spend.members.first { $0.userId == me.userId }
            let newSnapshot = DashboardSnapshot(
                email: me.email,
                planRequestsUsed: planRequestsUsed,
                totalRequestsAllModels: totalAll,
                spendingCents: mySpend?.spendCents ?? 0,
                hardLimitDollars: mySpend?.hardLimitOverrideDollars ?? 0
            )

            let creds = Credentials(
                userId: me.userId,
                workosId: me.workosId,
                email: me.email,
                teamId: me.teamId,
                cookieHeader: cookieHeader
            )
            try await self.storage.saveCredentials(creds)
            self.credentials = creds
            self.snapshot = newSnapshot
            try? await self.storage.saveDashboardSnapshot(newSnapshot)
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
            let planRequestsUsed = usage.models.values.map(\.requestsUsed).reduce(0, +)
            let totalAll = usage.models.values.map(\.totalRequests).reduce(0, +)
            let mySpend = spend.members.first { $0.userId == creds.userId }
            let newSnapshot = DashboardSnapshot(
                email: creds.email,
                planRequestsUsed: planRequestsUsed,
                totalRequestsAllModels: totalAll,
                spendingCents: mySpend?.spendCents ?? 0,
                hardLimitDollars: mySpend?.hardLimitOverrideDollars ?? 0
            )
            self.snapshot = newSnapshot
            try? await self.storage.saveDashboardSnapshot(newSnapshot)
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

    private func fetchUsageHistory() async {
        guard let creds = credentials else { return }
        self.isLoadingHistory = true
        defer { self.isLoadingHistory = false }
        do {
            let (startMs, endMs) = self.dayRangeMs(for: selectedDate)
            let history = try await service.fetchFilteredUsageEvents(
                teamId: creds.teamId,
                startDateMs: startMs,
                endDateMs: endMs,
                userId: creds.userId,
                page: 1,
                pageSize: max(historyLimit, 1),
                cookieHeader: creds.cookieHeader
            )
            self.usageEvents = history.events
        } catch {
            self.lastErrorMessage = error.localizedDescription
        }
    }

    private func dayRangeMs(for date: Date) -> (String, String) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        let endOfDay = Date(timeInterval: -0.001, since: nextDay)
        let startMs = String(Int(startOfDay.timeIntervalSince1970 * 1000))
        let endMs = String(Int(endOfDay.timeIntervalSince1970 * 1000))
        return (startMs, endMs)
    }

    private func formatTimestamp(_ msString: String) -> String {
        guard let ms = Double(msString) else { return msString }
        let date = Date(timeIntervalSince1970: ms / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
