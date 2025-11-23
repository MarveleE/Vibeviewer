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
            // 计算时间范围
            let (analyticsStartMs, analyticsEndMs) = self.analyticsDateRangeMs()
            
            // 使用 async let 并发发起所有独立的 API 请求
            async let usageSummary = try await self.api.fetchUsageSummary(
                cookieHeader: creds.cookieHeader
            )
            async let history = try await self.api.fetchFilteredUsageEvents(
                startDateMs: analyticsStartMs,
                endDateMs: analyticsEndMs,
                userId: creds.userId,
                page: 1,
                cookieHeader: creds.cookieHeader
            )
            async let billingCycleMs = try? await self.api.fetchCurrentBillingCycleMs(
                cookieHeader: creds.cookieHeader
            )

            // 等待 usageSummary，用于判断账号类型
            let usageSummaryValue = try await usageSummary
            
            // Pro 用户使用 filtered usage events 获取图表数据（700 条）
            // Team/Enterprise 用户使用 models analytics API
            let modelsUsageChart = try? await self.fetchModelsUsageChartForUser(
                usageSummary: usageSummaryValue,
                creds: creds,
                analyticsStartMs: analyticsStartMs,
                analyticsEndMs: analyticsEndMs
            )
            
            // 获取计费周期（毫秒时间戳格式）
            let billingCycleValue = await billingCycleMs
            
            // totalRequestsAllModels 将基于使用事件计算，而非API返回的请求数据
            let totalAll = 0 // 暂时设为0，后续通过使用事件更新

            let current = self.session.snapshot

            // Team Plan free usage（依赖 usageSummary 判定）
            func computeFreeCents() async -> Int {
                if usageSummaryValue.membershipType == .enterprise && creds.isEnterpriseUser == false {
                    return (try? await self.api.fetchTeamFreeUsageCents(
                        teamId: creds.teamId,
                        userId: creds.userId,
                        cookieHeader: creds.cookieHeader
                    )) ?? 0
                }
                return 0
            }
            let freeCents = await computeFreeCents()
            
            // 获取聚合使用事件（仅限 Pro 系列账号，非 Team）
            func fetchModelsUsageSummaryIfNeeded(billingCycleStartMs: String) async -> VibeviewerModel.ModelsUsageSummary? {
                // 仅 Pro 系列账号才获取（Pro / Pro+ / Ultra，非 Team / Enterprise）
                let isProAccount = usageSummaryValue.membershipType.isProSeries
                guard isProAccount else { return nil }
                
                // 使用账单周期的开始时间（毫秒时间戳）
                let startDateMs = Int64(billingCycleStartMs) ?? 0
                
                let aggregated = try? await self.api.fetchAggregatedUsageEvents(
                    teamId: -1,
                    startDate: startDateMs,
                    cookieHeader: creds.cookieHeader
                )
                
                return aggregated.map { VibeviewerModel.ModelsUsageSummary(from: $0) }
            }
            var modelsUsageSummary: VibeviewerModel.ModelsUsageSummary? = nil
            if let billingCycleStartMs = billingCycleValue?.startDateMs {
                modelsUsageSummary = await fetchModelsUsageSummaryIfNeeded(billingCycleStartMs: billingCycleStartMs)
            }

            // 先更新一次概览（使用旧历史事件），提升 UI 及时性
            let overview = DashboardSnapshot(
                email: creds.email,
                totalRequestsAllModels: totalAll,
                spendingCents: usageSummaryValue.individualUsage.plan.used,
                hardLimitDollars: usageSummaryValue.individualUsage.plan.limit / 100,
                usageEvents: current?.usageEvents ?? [],
                requestToday: current?.requestToday ?? 0,
                requestYestoday: current?.requestYestoday ?? 0,
                usageSummary: usageSummaryValue,
                freeUsageCents: freeCents,
                modelsUsageChart: current?.modelsUsageChart,
                modelsUsageSummary: modelsUsageSummary,
                billingCycleStartMs: billingCycleValue?.startDateMs,
                billingCycleEndMs: billingCycleValue?.endDateMs
            )
            self.session.snapshot = overview
            try? await self.storage.saveDashboardSnapshot(overview)

            // 等待并合并历史事件数据
            let historyValue = try await history
            let (reqToday, reqYesterday) = self.splitTodayAndYesterdayCounts(from: historyValue.events)
            let merged = DashboardSnapshot(
                email: overview.email,
                totalRequestsAllModels: overview.totalRequestsAllModels,
                spendingCents: overview.spendingCents,
                hardLimitDollars: overview.hardLimitDollars,
                usageEvents: historyValue.events,
                requestToday: reqToday,
                requestYestoday: reqYesterday,
                usageSummary: usageSummaryValue,
                freeUsageCents: overview.freeUsageCents,
                modelsUsageChart: modelsUsageChart,
                modelsUsageSummary: modelsUsageSummary,
                billingCycleStartMs: billingCycleValue?.startDateMs,
                billingCycleEndMs: billingCycleValue?.endDateMs
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

    private func analyticsDateRangeMs() -> (String, String) {
        let days = self.settings.analyticsDataDays
        let (start, end) = VibeviewerCore.DateUtils.daysAgoToNowRange(days: days)
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
    
    /// 计算模型分析的时间范围：使用设置中的分析数据范围天数
    private func modelsAnalyticsDateRange() -> (start: String, end: String) {
        let days = self.settings.analyticsDataDays
        return VibeviewerCore.DateUtils.daysAgoToTodayRange(days: days)
    }
    
    /// 根据账号类型获取模型使用量图表数据
    /// - 非 Team 账号（Pro / Pro+ / Ultra / Free 等）：使用 filtered usage events（700 条）
    /// - Team Plan 账号：使用 models analytics API（/api/v2/analytics/team/models）
    private func fetchModelsUsageChartForUser(
        usageSummary: VibeviewerModel.UsageSummary,
        creds: Credentials,
        analyticsStartMs: String,
        analyticsEndMs: String
    ) async throws -> VibeviewerModel.ModelsUsageChartData {
        // 仅 Team Plan 账号调用 team analytics 接口：
        // - 后端使用 membershipType = .enterprise + isEnterpriseUser = false 表示 Team Plan
        let isTeamPlanAccount = (usageSummary.membershipType == .enterprise && creds.isEnterpriseUser == false)
        
        // 非 Team 账号一律使用 filtered usage events，避免误调 /api/v2/analytics/team/ 系列接口
        guard isTeamPlanAccount else {
            return try await self.api.fetchModelsUsageChartFromEvents(
                startDateMs: analyticsStartMs,
                endDateMs: analyticsEndMs,
                userId: creds.userId,
                cookieHeader: creds.cookieHeader
            )
        }
        
        // Team Plan 用户使用 models analytics API
        let dateRange = self.modelsAnalyticsDateRange()
        return try await self.api.fetchModelsAnalytics(
            startDate: dateRange.start,
            endDate: dateRange.end,
            c: creds.workosId,
            cookieHeader: creds.cookieHeader
        )
    }
}


