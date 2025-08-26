import Foundation
import Observation
import VibeviewerAPI
import VibeviewerModel
import VibeviewerStorage
import VibeviewerCore

/// 后台刷新服务协议
public protocol DashboardRefreshService: Sendable {
    @MainActor var isRefreshing: Bool { get }
    @MainActor func start() async
    @MainActor func stop()
    @MainActor func refreshNow() async
}

/// 无操作默认实现，便于提供 Environment 默认值
public struct NoopDashboardRefreshService: DashboardRefreshService {
    public init() {}
    public var isRefreshing: Bool { false }
    @MainActor public func start() async {}
    @MainActor public func stop() {}
    @MainActor public func refreshNow() async {}
}

@MainActor
@Observable
public final class DefaultDashboardRefreshService: DashboardRefreshService {
    private let api: CursorService
    private let storage: any CursorStorageService
    private let settings: AppSettings
    private let session: AppSession
    private var loopTask: Task<Void, Never>?
    public private(set) var isRefreshing: Bool = false

    public init(
        api: CursorService,
        storage: any CursorStorageService,
        settings: AppSettings,
        session: AppSession
    ) {
        self.api = api
        self.storage = storage
        self.settings = settings
        self.session = session
    }

    public func start() async {
        await self.bootstrapIfNeeded()
        await self.refreshNow()

        self.loopTask?.cancel()
        self.loopTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refreshNow()
                // 固定 5 分钟刷新一次
                try? await Task.sleep(for: .seconds(5 * 60))
            }
        }
    }

    public func stop() {
        self.loopTask?.cancel()
        self.loopTask = nil
    }

    public func refreshNow() async {
        if self.isRefreshing { return }
        self.isRefreshing = true
        defer { self.isRefreshing = false }
        await self.bootstrapIfNeeded()
        guard let creds = self.session.credentials else { return }

        do {
            // 概览并发拉取
            async let usageAsync = self.api.fetchUsage(workosUserId: creds.workosId, cookieHeader: creds.cookieHeader)
            async let spendAsync = self.api.fetchTeamSpend(teamId: creds.teamId, cookieHeader: creds.cookieHeader)
            let usage = try await usageAsync
            let spend = try await spendAsync

            let planRequestsUsed = usage.models.map(\.requestsUsed).reduce(0, +)
            let totalAll = usage.models.map(\.totalRequests).reduce(0, +)
            let mySpend = spend.members.first { $0.userId == creds.userId }

            let current = self.session.snapshot
            let overview = DashboardSnapshot(
                email: creds.email,
                planRequestsUsed: planRequestsUsed,
                planIncludeRequestCount: mySpend?.fastPremiumRequests ?? (current?.planIncludeRequestCount ?? 0),
                totalRequestsAllModels: totalAll,
                spendingCents: mySpend?.spendCents ?? (current?.spendingCents ?? 0),
                hardLimitDollars: mySpend?.hardLimitOverrideDollars ?? (current?.hardLimitDollars ?? 0),
                usageEvents: current?.usageEvents ?? [],
                requestToday: current?.requestToday ?? 0,
                requestYestoday: current?.requestYestoday ?? 0
            )
            self.session.snapshot = overview
            try? await self.storage.saveDashboardSnapshot(overview)

            // 历史事件与当日/昨日统计
            let (startMs, endMs) = self.yesterdayToNowRangeMs()
            let history = try await self.api.fetchFilteredUsageEvents(
                teamId: creds.teamId,
                startDateMs: startMs,
                endDateMs: endMs,
                userId: creds.userId,
                page: 1,
                pageSize: 100,
                cookieHeader: creds.cookieHeader
            )

            let (reqToday, reqYesterday) = self.splitTodayAndYesterdayCounts(from: history.events)
            let merged = DashboardSnapshot(
                email: overview.email,
                planRequestsUsed: overview.planRequestsUsed,
                planIncludeRequestCount: overview.planIncludeRequestCount,
                totalRequestsAllModels: overview.totalRequestsAllModels,
                spendingCents: overview.spendingCents,
                hardLimitDollars: overview.hardLimitDollars,
                usageEvents: history.events,
                requestToday: reqToday,
                requestYestoday: reqYesterday
            )
            self.session.snapshot = merged
            try? await self.storage.saveDashboardSnapshot(merged)
        } catch {
            // 静默失败
        }
    }

    private func bootstrapIfNeeded() async {
        if self.session.snapshot == nil, let cached = await self.storage.loadDashboardSnapshot() {
            self.session.snapshot = cached
        }
        if self.session.credentials == nil {
            self.session.credentials = await self.storage.loadCredentials()
        }
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
}


