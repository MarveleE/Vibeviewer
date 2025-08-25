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
    @Environment(AppSession.self) private var session

    enum ViewState: Equatable {
        case loading
        case loaded
        case error(String)
    }

    public init() {}

    @State private var state: ViewState = .loading
    @State private var refreshTask: Task<Void, Never>?

    public var body: some View {
        @Bindable var appSettings = appSettings

        VStack(alignment: .leading, spacing: 12) {
            DashboardSummaryView(snapshot: session.snapshot)
            
            if case .error(let message) = state {
                ErrorBannerView(message: message)
            }

            ActionButtonsView(
                isLoading: state == .loading,
                isLoggedIn: session.credentials != nil,
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
                isLoading: state == .loading,
                settings: appSettings,
                events: session.snapshot?.usageEvents ?? [],
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
            self.session.snapshot = cached
        }

        // 读取登录态
        let creds = await self.storage.loadCredentials()
        self.session.credentials = creds
        if self.session.credentials != nil {
            await self.reloadOverviewAndPersist()
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
        self.session.credentials = nil
        self.session.snapshot = nil
        self.refreshTask?.cancel()
        self.refreshTask = nil
    }

    private func completeLogin(cookieHeader: String) async {
        self.state = .loading
        do {
            let me = try await service.fetchMe(cookieHeader: cookieHeader)
            try await self.storage.saveCredentials(me)
            self.session.credentials = me
            await self.reloadOverviewAndPersist()
            self.startAutoRefresh()
        } catch {
            self.state = .error(error.localizedDescription)
        }
    }

    private func refresh() async {
        guard session.credentials != nil else { return }
        self.state = .loading
        await self.reloadOverviewAndPersist()
    }

    private func fetchUsageHistory() async {
        guard let creds = session.credentials else { return }
        self.state = .loading
        defer { self.state = .loaded }
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
            let newSnapshot = DashboardSnapshot(
                email: creds.email,
                planRequestsUsed: session.snapshot?.planRequestsUsed ?? 0,
                totalRequestsAllModels: session.snapshot?.totalRequestsAllModels ?? 0,
                spendingCents: session.snapshot?.spendingCents ?? 0,
                hardLimitDollars: session.snapshot?.hardLimitDollars ?? 0,
                usageEvents: history.events
            )
            self.session.snapshot = newSnapshot
            try? await self.storage.saveDashboardSnapshot(newSnapshot)
        } catch {
            self.state = .error(error.localizedDescription)
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

    

    private func reloadOverviewAndPersist() async {
        guard let creds = session.credentials else { return }
        self.state = .loading
        defer { self.state = .loaded }
        do {
            async let usageAsync = service.fetchUsage(workosUserId: creds.workosId, cookieHeader: creds.cookieHeader)
            async let spendAsync = service.fetchTeamSpend(teamId: creds.teamId, cookieHeader: creds.cookieHeader)
            let usage = try await usageAsync
            let spend = try await spendAsync

            let planRequestsUsed = usage.models.values.map { $0.requestsUsed }.reduce(0, +)
            let totalAll = usage.models.values.map { $0.totalRequests }.reduce(0, +)
            let mySpend = spend.members.first { $0.userId == creds.userId }

            let newSnapshot = DashboardSnapshot(
                email: creds.email,
                planRequestsUsed: planRequestsUsed,
                totalRequestsAllModels: totalAll,
                spendingCents: mySpend?.spendCents ?? 0,
                hardLimitDollars: mySpend?.hardLimitOverrideDollars ?? 0,
                usageEvents: session.snapshot?.usageEvents ?? []
            )
            self.session.snapshot = newSnapshot
            try? await self.storage.saveDashboardSnapshot(newSnapshot)
        } catch {
            if case CursorServiceError.sessionExpired = error {
                await self.setLoggedOut()
                self.state = .error("会话已过期，请重新登录")   
            } else {
                self.state = .error(error.localizedDescription)
            }
        }
    }
}
