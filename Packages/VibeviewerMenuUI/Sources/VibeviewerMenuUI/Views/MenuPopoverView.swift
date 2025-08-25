import SwiftUI
import VibeviewerAPI
import VibeviewerAppEnvironment
import VibeviewerLoginUI
import VibeviewerModel
import VibeviewerSettingsUI
import Observation

@MainActor
public struct MenuPopoverView: View {
    @Environment(\.cursorService) private var service
    @Environment(\.cursorStorage) private var storage
    @Environment(\.loginWindowManager) private var loginWindow
    @Environment(\.settingsWindowManager) private var settingsWindow
    @Environment(AppSettings.self) private var appSettings

    enum ViewState {
        case loading
        case loaded
        case error(String)
    }

    @State private var credentials: Credentials?
    @State private var snapshot: DashboardSnapshot?
    @State private var lastErrorMessage: String?
    @State private var refreshTask: Task<Void, Never>?

    // Usage History (filtered by date)
    @State private var usageEvents: [VibeviewerModel.UsageEvent] = []
    @State private var isLoadingHistory: Bool = false

    // Split states for granular fetching
    @State private var usageOverview: UsageOverview?
    @State private var teamSpend: TeamSpendOverview?
    @State private var isLoadingUsage: Bool = false
    @State private var isLoadingSpend: Bool = false

    public init(initialCredentials: Credentials? = nil, initialSnapshot: DashboardSnapshot? = nil) {
        self._credentials = State(initialValue: initialCredentials)
        self._snapshot = State(initialValue: initialSnapshot)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSummaryView(snapshot: snapshot)

            ErrorBannerView(message: lastErrorMessage)

            ActionButtonsView(
                isLoading: (isLoadingUsage || isLoadingSpend),
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
                selectedDate: selectedDateBinding,
                historyLimit: historyLimitBinding,
                events: usageEvents,
                onReload: { Task { await fetchUsageHistory() } },
                onToday: { appSettings.usageHistory.dateRange.start = Date() }
            )
        }
        .padding(16)
        .frame(minWidth: 320)
        .task { await self.loadInitial() }
        .onChange(of: appSettings.usageHistory.dateRange.start) { _, _ in Task { await fetchUsageHistory() } }
        .onChange(of: appSettings.usageHistory.limit) { _, _ in Task { await fetchUsageHistory() } }
    }

    private func loadInitial() async {
        // 先从本地读取最近一次的快照，避免冷启动空白
        if let cached = await self.storage.loadDashboardSnapshot() {
            self.snapshot = cached
        }

        // 读取登录态
        self.credentials = await self.storage.loadCredentials()
        if self.credentials != nil {
            // 并行拉取每一块数据
            async let a: Void = self.reloadUsage()
            async let b: Void = self.reloadTeamSpend()
            _ = await (a, b)
            self.startAutoRefresh()
            await self.fetchUsageHistory()
        }
    }

    private func startAutoRefresh() {
        self.refreshTask?.cancel()
        self.refreshTask = Task {
            while !Task.isCancelled {
                await self.refresh()
                let minutes = max(appSettings.overview.refreshInterval, 1)
                try? await Task.sleep(for: .seconds(Double(minutes) * 60))
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
        self.lastErrorMessage = nil
        do {
            let me = try await service.fetchMe(cookieHeader: cookieHeader)
            let creds = Credentials(
                userId: me.userId,
                workosId: me.workosId,
                email: me.email,
                teamId: me.teamId,
                cookieHeader: cookieHeader
            )
            try await self.storage.saveCredentials(creds)
            self.credentials = creds
            // 并行拉取各块数据
            async let a: Void = self.reloadUsage()
            async let b: Void = self.reloadTeamSpend()
            _ = await (a, b)
            self.startAutoRefresh()
        } catch {
            self.lastErrorMessage = error.localizedDescription
        }
    }

    private func refresh() async {
        guard credentials != nil else { return }
        self.lastErrorMessage = nil
        async let a: Void = self.reloadUsage()
        async let b: Void = self.reloadTeamSpend()
        _ = await (a, b)
    }

    private func fetchUsageHistory() async {
        guard let creds = credentials else { return }
        self.isLoadingHistory = true
        defer { self.isLoadingHistory = false }
        do {
            let (startMs, endMs) = self.dayRangeMs(for: appSettings.usageHistory.dateRange.start)
            let history = try await service.fetchFilteredUsageEvents(
                teamId: creds.teamId,
                startDateMs: startMs,
                endDateMs: endMs,
                userId: creds.userId,
                page: 1,
                pageSize: max(appSettings.usageHistory.limit, 1),
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

    

    private func reloadUsage() async {
        guard let creds = credentials else { return }
        self.isLoadingUsage = true
        defer { self.isLoadingUsage = false }
        do {
            let usage = try await service.fetchUsage(workosUserId: creds.workosId, cookieHeader: creds.cookieHeader)
            self.usageOverview = usage
            await self.composeSnapshotIfPossibleAndPersist()
        } catch {
            if case CursorServiceError.sessionExpired = error {
                await self.setLoggedOut()
                self.lastErrorMessage = "会话已过期，请重新登录"
            } else {
                self.lastErrorMessage = error.localizedDescription
            }
        }
    }

    private func reloadTeamSpend() async {
        guard let creds = credentials else { return }
        self.isLoadingSpend = true
        defer { self.isLoadingSpend = false }
        do {
            let spend = try await service.fetchTeamSpend(teamId: creds.teamId, cookieHeader: creds.cookieHeader)
            self.teamSpend = spend
            await self.composeSnapshotIfPossibleAndPersist()
        } catch {
            if case CursorServiceError.sessionExpired = error {
                await self.setLoggedOut()
                self.lastErrorMessage = "会话已过期，请重新登录"
            } else {
                self.lastErrorMessage = error.localizedDescription
            }
        }
    }

    private func composeSnapshotIfPossibleAndPersist() async {
        guard let creds = credentials, let usage = usageOverview, let spend = teamSpend else { return }
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
    }
}

// MARK: - Bindings into AppSettings
extension MenuPopoverView {
    private var selectedDateBinding: Binding<Date> {
        Binding(
            get: { appSettings.usageHistory.dateRange.start },
            set: { appSettings.usageHistory.dateRange.start = $0 }
        )
    }

    private var historyLimitBinding: Binding<Int> {
        Binding(
            get: { appSettings.usageHistory.limit },
            set: { appSettings.usageHistory.limit = max(1, $0) }
        )
    }
}
