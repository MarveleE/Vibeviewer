import Observation
import SwiftUI
import VibeviewerAPI
import VibeviewerAppEnvironment
import VibeviewerLoginUI
import VibeviewerModel
import VibeviewerSettingsUI
import VibeviewerCore
import VibeviewerShareUI

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

        VStack(alignment: .leading, spacing: 16) {
            UsageHeaderView { action in
                switch action {
                case .dashboard:
                    self.settingsWindow.show()
                }
            }

            if let snapshot = self.session.snapshot {
                MetricsView(metric: .billing(snapshot.billingMetrics))
                MetricsView(metric: .planRequests(snapshot.planRequestsMetrics))
            }

            Divider().opacity(0.5)

            RequestsCompareView(requestToday: self.session.snapshot?.requestToday ?? 0, requestYestoday: self.session.snapshot?.requestYestoday ?? 0)
            
            Divider().opacity(0.5)

            UsageEventView(events: self.session.snapshot?.usageEvents ?? [])
            
            Divider().opacity(0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(width: 300, alignment: .top)
        .background {
            ZStack {
                Color(hex: "0D0C0C")
                Circle()
                    .fill(Color(hex: "6D8A84"))
                    .padding(80)
                    .blur(radius: 200)
            }
            .cornerRadius(32 - 4)
        }
        .padding(4)
        .compositingGroup()
        .geometryGroup()
        .task { await self.loadInitial() }
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
        guard self.session.credentials != nil else { return }
        self.state = .loading
        await self.reloadOverviewAndPersist()
    }

    private func fetchUsageHistory() async {
        guard let creds = session.credentials else { return }
        self.state = .loading
        defer { self.state = .loaded }
        do {
            let (startMs, endMs) = self.yesterdayToNowRangeMs()
            let history = try await service.fetchFilteredUsageEvents(
                teamId: creds.teamId,
                startDateMs: startMs,
                endDateMs: endMs,
                userId: creds.userId,
                page: 1,
                pageSize: 100,
                cookieHeader: creds.cookieHeader
            )
            let (reqToday, reqYesterday) = self.splitTodayAndYesterdayCounts(from: history.events)
            let newSnapshot = DashboardSnapshot(
                email: creds.email,
                planRequestsUsed: self.session.snapshot?.planRequestsUsed ?? 0,
                planIncludeRequestCount: self.session.snapshot?.planIncludeRequestCount ?? 0,
                totalRequestsAllModels: self.session.snapshot?.totalRequestsAllModels ?? 0,
                spendingCents: self.session.snapshot?.spendingCents ?? 0,
                hardLimitDollars: self.session.snapshot?.hardLimitDollars ?? 0,
                usageEvents: history.events,
                requestToday: reqToday,
                requestYestoday: reqYesterday
            )
            self.session.snapshot = newSnapshot
            try? await self.storage.saveDashboardSnapshot(newSnapshot)
        } catch {
            self.state = .error(error.localizedDescription)
        }
    }

    private func dayRangeMs(for date: Date) -> (String, String) {
        let (start, end) = VibeviewerCore.DateUtils.dayRange(for: date)
        return (VibeviewerCore.DateUtils.millisecondsString(from: start), VibeviewerCore.DateUtils.millisecondsString(from: end))
    }

    private func yesterdayToNowRangeMs() -> (String, String) {
        let (start, end) = VibeviewerCore.DateUtils.yesterdayToNowRange()
        return (VibeviewerCore.DateUtils.millisecondsString(from: start), VibeviewerCore.DateUtils.millisecondsString(from: end))
    }

    private func splitTodayAndYesterdayCounts(from events: [UsageEvent]) -> (Int, Int) {
        let calendar = Calendar.current
        var today = 0
        var yesterday = 0
        for e in events {
            guard let date = VibeviewerCore.DateUtils.date(fromMillisecondsString: e.occurredAtMs) else { continue }
            if calendar.isDateInToday(date) {
                today += e.requestCostCount
            } else if calendar.isDateInYesterday(date) {
                yesterday += e.requestCostCount
            }
        }
        return (today, yesterday)
    }

    // 日期解析方法已迁移至 Core 的 Date 扩展

    private func reloadOverviewAndPersist() async {
        guard let creds = session.credentials else { return }
        self.state = .loading
        defer { self.state = .loaded }
        do {
            async let usageAsync = self.service.fetchUsage(workosUserId: creds.workosId, cookieHeader: creds.cookieHeader)
            async let spendAsync = self.service.fetchTeamSpend(teamId: creds.teamId, cookieHeader: creds.cookieHeader)
            let usage = try await usageAsync
            let spend = try await spendAsync

            let planRequestsUsed = usage.models.map(\.requestsUsed).reduce(0, +)
            let totalAll = usage.models.map(\.totalRequests).reduce(0, +)
            let mySpend = spend.members.first { $0.userId == creds.userId }

            let newSnapshot = DashboardSnapshot(
                email: creds.email,
                planRequestsUsed: planRequestsUsed,
                planIncludeRequestCount: mySpend?.fastPremiumRequests ?? 0,
                totalRequestsAllModels: totalAll,
                spendingCents: mySpend?.spendCents ?? 0,
                hardLimitDollars: mySpend?.hardLimitOverrideDollars ?? 0,
                usageEvents: self.session.snapshot?.usageEvents ?? [],
                requestToday: self.session.snapshot?.requestToday ?? 0,
                requestYestoday: self.session.snapshot?.requestYestoday ?? 0
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
