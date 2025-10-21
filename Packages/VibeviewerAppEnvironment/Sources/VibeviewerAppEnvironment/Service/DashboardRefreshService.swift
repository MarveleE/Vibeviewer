import Foundation
import Observation
import VibeviewerAPI
import VibeviewerModel
import VibeviewerStorage
import VibeviewerCore

/// 后台刷新服务协议
public protocol DashboardRefreshService: Sendable {
    @MainActor var isRefreshing: Bool { get }
    @MainActor var isPaused: Bool { get }
    @MainActor func start() async
    @MainActor func stop()
    @MainActor func pause()
    @MainActor func resume() async
    @MainActor func refreshNow() async
}

/// 无操作默认实现，便于提供 Environment 默认值
public struct NoopDashboardRefreshService: DashboardRefreshService {
    public init() {}
    public var isRefreshing: Bool { false }
    public var isPaused: Bool { false }
    @MainActor public func start() async {}
    @MainActor public func stop() {}
    @MainActor public func pause() {}
    @MainActor public func resume() async {}
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
    public private(set) var isPaused: Bool = false

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
                // 如果暂停，则等待一段时间后再检查
                if self.isPaused {
                    try? await Task.sleep(for: .seconds(30)) // 暂停时每30秒检查一次状态
                    continue
                }
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

    public func pause() {
        self.isPaused = true
    }

    public func resume() async {
        self.isPaused = false
        // 立即刷新一次
        await self.refreshNow()
    }

    public func refreshNow() async {
        if self.isRefreshing || self.isPaused { return }
        self.isRefreshing = true
        defer { self.isRefreshing = false }
        await self.bootstrapIfNeeded()
        guard let creds = self.session.credentials else { return }

        do {
            // 并发发起与凭据无依赖的请求（使用 Task 而非 async let，规避静态分析误报）
            let (startMs, endMs) = self.yesterdayToNowRangeMs()
            let usageSummaryTask = Task { () throws -> UsageSummary in
                try await self.api.fetchUsageSummary(cookieHeader: creds.cookieHeader)
            }
            let historyTask = Task { () throws -> FilteredUsageHistory in
                try await self.api.fetchFilteredUsageEvents(
                    teamId: creds.teamId,
                    startDateMs: startMs,
                    endDateMs: endMs,
                    userId: creds.userId,
                    page: 1,
                    pageSize: 100,
                    cookieHeader: creds.cookieHeader
                )
            }

            // 先拿到 usageSummary，用于判断 Team Plan
            let usageSummary = try await usageSummaryTask.value

            // totalRequestsAllModels 将基于使用事件计算，而非API返回的请求数据
            let totalAll = 0 // 暂时设为0，后续通过使用事件更新

            let current = self.session.snapshot

            // Team Plan free usage（依赖 usageSummary 判定）
            func computeFreeCents() async -> Int {
                if usageSummary.membershipType == .enterprise && creds.isEnterpriseUser == false {
                    return (try? await self.api.fetchTeamFreeUsageCents(teamId: creds.teamId, userId: creds.userId, cookieHeader: creds.cookieHeader)) ?? 0
                }
                return 0
            }
            let freeCents = await computeFreeCents()

            // 先更新一次概览（使用旧历史事件），提升 UI 及时性
            let overview = DashboardSnapshot(
                email: creds.email,
                totalRequestsAllModels: totalAll,
                spendingCents: usageSummary.individualUsage.plan.used,
                hardLimitDollars: usageSummary.individualUsage.plan.limit / 100,
                usageEvents: current?.usageEvents ?? [],
                requestToday: current?.requestToday ?? 0,
                requestYestoday: current?.requestYestoday ?? 0,
                usageSummary: usageSummary,
                freeUsageCents: freeCents
            )
            self.session.snapshot = overview
            try? await self.storage.saveDashboardSnapshot(overview)

            // 等待并合并历史事件
            let history = try await historyTask.value
            let (reqToday, reqYesterday) = self.splitTodayAndYesterdayCounts(from: history.events)
            let merged = DashboardSnapshot(
                email: overview.email,
                totalRequestsAllModels: overview.totalRequestsAllModels,
                spendingCents: overview.spendingCents,
                hardLimitDollars: overview.hardLimitDollars,
                usageEvents: history.events,
                requestToday: reqToday,
                requestYestoday: reqYesterday,
                usageSummary: usageSummary,
                freeUsageCents: overview.freeUsageCents
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


