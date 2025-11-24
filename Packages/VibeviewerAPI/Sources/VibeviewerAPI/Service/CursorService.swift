import Foundation
import Moya
import VibeviewerModel
import VibeviewerCore

public enum CursorServiceError: Error {
    case sessionExpired
}

protocol CursorNetworkClient {
    func decodableRequest<T: DecodableTargetType>(
        _ target: T,
        decodingStrategy: JSONDecoder.KeyDecodingStrategy
    ) async throws -> T
        .ResultType
}

struct DefaultCursorNetworkClient: CursorNetworkClient {
    init() {}

    func decodableRequest<T>(_ target: T, decodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> T
        .ResultType where T: DecodableTargetType
    {
        try await HttpClient.decodableRequest(target, decodingStrategy: decodingStrategy)
    }
}

public protocol CursorService {
    func fetchMe(cookieHeader: String) async throws -> Credentials
    func fetchUsageSummary(cookieHeader: String) async throws -> VibeviewerModel.UsageSummary
    /// 仅 Team Plan 使用：返回当前用户的 free usage（以分计）。计算方式：includedSpendCents - hardLimitOverrideDollars*100，若小于0则为0
    func fetchTeamFreeUsageCents(teamId: Int, userId: Int, cookieHeader: String) async throws -> Int
    func fetchFilteredUsageEvents(
        startDateMs: String,
        endDateMs: String,
        userId: Int,
        page: Int,
        cookieHeader: String
    ) async throws -> VibeviewerModel.FilteredUsageHistory
    func fetchModelsAnalytics(
        startDate: String,
        endDate: String,
        c: String,
        cookieHeader: String
    ) async throws -> VibeviewerModel.ModelsUsageChartData
    /// 获取聚合使用事件（仅限 Pro 账号，非 Team 账号）
    /// - Parameters:
    ///   - teamId: 团队 ID，Pro 账号传 nil
    ///   - startDate: 开始日期（毫秒时间戳）
    ///   - cookieHeader: Cookie 头
    func fetchAggregatedUsageEvents(
        teamId: Int?,
        startDate: Int64,
        cookieHeader: String
    ) async throws -> VibeviewerModel.AggregatedUsageEvents
    /// 获取当前计费周期
    /// - Parameter cookieHeader: Cookie 头
    func fetchCurrentBillingCycle(cookieHeader: String) async throws -> VibeviewerModel.BillingCycle
    /// 获取当前计费周期（返回原始毫秒时间戳字符串）
    /// - Parameter cookieHeader: Cookie 头
    /// - Returns: (startDateMs: String, endDateMs: String) 毫秒时间戳字符串
    func fetchCurrentBillingCycleMs(cookieHeader: String) async throws -> (startDateMs: String, endDateMs: String)
    /// 通过 Filtered Usage Events 获取模型使用量图表数据（Pro 用户替代方案）
    /// - Parameters:
    ///   - startDateMs: 开始日期（毫秒时间戳）
    ///   - endDateMs: 结束日期（毫秒时间戳）
    ///   - userId: 用户 ID
    ///   - cookieHeader: Cookie 头
    /// - Returns: 模型使用量图表数据
    func fetchModelsUsageChartFromEvents(
        startDateMs: String,
        endDateMs: String,
        userId: Int,
        cookieHeader: String
    ) async throws -> VibeviewerModel.ModelsUsageChartData
}

public struct DefaultCursorService: CursorService {
    private let network: CursorNetworkClient
    private let decoding: JSONDecoder.KeyDecodingStrategy

    // Public initializer that does not expose internal protocol types
    public init(decoding: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) {
        self.network = DefaultCursorNetworkClient()
        self.decoding = decoding
    }

    // Internal injectable initializer for tests
    init(network: any CursorNetworkClient, decoding: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) {
        self.network = network
        self.decoding = decoding
    }

    private func performRequest<T: DecodableTargetType>(_ target: T) async throws -> T.ResultType {
        do {
            return try await self.network.decodableRequest(target, decodingStrategy: self.decoding)
        } catch {
            if let moyaError = error as? MoyaError,
               case let .statusCode(response) = moyaError,
               [401, 403].contains(response.statusCode)
            {
                throw CursorServiceError.sessionExpired
            }
            throw error
        }
    }

    public func fetchMe(cookieHeader: String) async throws -> Credentials {
        let dto: CursorMeResponse = try await self.performRequest(CursorGetMeAPI(cookieHeader: cookieHeader))
        return Credentials(
            userId: dto.userId,
            workosId: dto.workosId,
            email: dto.email,
            teamId: dto.teamId ?? 0,
            cookieHeader: cookieHeader,
            isEnterpriseUser: dto.isEnterpriseUser
        )
    }

    public func fetchUsageSummary(cookieHeader: String) async throws -> VibeviewerModel.UsageSummary {
        let dto: CursorUsageSummaryResponse = try await self.performRequest(CursorUsageSummaryAPI(cookieHeader: cookieHeader))
        
        // 解析日期
        let dateFormatter = ISO8601DateFormatter()
        let billingCycleStart = dateFormatter.date(from: dto.billingCycleStart) ?? Date()
        let billingCycleEnd = dateFormatter.date(from: dto.billingCycleEnd) ?? Date()
        
        // 映射计划使用情况
        let planUsage = VibeviewerModel.PlanUsage(
            used: dto.individualUsage.plan.used,
            limit: dto.individualUsage.plan.limit,
            remaining: dto.individualUsage.plan.remaining,
            breakdown: VibeviewerModel.PlanBreakdown(
                included: dto.individualUsage.plan.breakdown.included,
                bonus: dto.individualUsage.plan.breakdown.bonus,
                total: dto.individualUsage.plan.breakdown.total
            )
        )
        
        // 映射按需使用情况（如果存在）
        let onDemandUsage: VibeviewerModel.OnDemandUsage? = {
            guard let individualOnDemand = dto.individualUsage.onDemand else { return nil }
            if individualOnDemand.used > 0 || (individualOnDemand.limit ?? 0) > 0 {
                return VibeviewerModel.OnDemandUsage(
                    used: individualOnDemand.used,
                    limit: individualOnDemand.limit,
                    remaining: individualOnDemand.remaining,
                    enabled: individualOnDemand.enabled
                )
            }
            return nil
        }()
        
        // 映射个人使用情况
        let individualUsage = VibeviewerModel.IndividualUsage(
            plan: planUsage,
            onDemand: onDemandUsage
        )
        
        // 映射团队使用情况（如果存在）
        let teamUsage: VibeviewerModel.TeamUsage? = {
            guard let teamUsageData = dto.teamUsage,
                  let teamOnDemand = teamUsageData.onDemand else { return nil }
            if teamOnDemand.used > 0 || (teamOnDemand.limit ?? 0) > 0 {
                return VibeviewerModel.TeamUsage(
                    onDemand: VibeviewerModel.OnDemandUsage(
                        used: teamOnDemand.used,
                        limit: teamOnDemand.limit,
                        remaining: teamOnDemand.remaining,
                        enabled: teamOnDemand.enabled
                    )
                )
            }
            return nil
        }()
        
        // 映射会员类型
        let membershipType = VibeviewerModel.MembershipType(rawValue: dto.membershipType) ?? .free
        
        return VibeviewerModel.UsageSummary(
            billingCycleStart: billingCycleStart,
            billingCycleEnd: billingCycleEnd,
            membershipType: membershipType,
            limitType: dto.limitType,
            individualUsage: individualUsage,
            teamUsage: teamUsage
        )
    }

    public func fetchFilteredUsageEvents(
        startDateMs: String,
        endDateMs: String,
        userId: Int,
        page: Int,
        cookieHeader: String
    ) async throws -> VibeviewerModel.FilteredUsageHistory {
        let dto: CursorFilteredUsageResponse = try await self.performRequest(
            CursorFilteredUsageAPI(
                startDateMs: startDateMs,
                endDateMs: endDateMs,
                userId: userId,
                page: page,
                cookieHeader: cookieHeader
            )
        )
        let events: [VibeviewerModel.UsageEvent] = (dto.usageEventsDisplay ?? []).map { e in
            let tokenUsage = VibeviewerModel.TokenUsage(
                outputTokens: e.tokenUsage.outputTokens,
                inputTokens: e.tokenUsage.inputTokens,
                totalCents: e.tokenUsage.totalCents ?? 0.0,
                cacheWriteTokens: e.tokenUsage.cacheWriteTokens,
                cacheReadTokens: e.tokenUsage.cacheReadTokens
            )
            
            // 计算请求次数：基于 token 使用情况，如果没有 token 信息则默认为 1
            let requestCount = Self.calculateRequestCount(from: e.tokenUsage)
            
            return VibeviewerModel.UsageEvent(
                occurredAtMs: e.timestamp,
                modelName: e.model,
                kind: e.kind,
                requestCostCount: requestCount,
                usageCostDisplay: e.usageBasedCosts,
                usageCostCents: Self.parseCents(fromDollarString: e.usageBasedCosts),
                isTokenBased: e.isTokenBasedCall,
                userDisplayName: e.owningUser,
                cursorTokenFee: e.cursorTokenFee,
                tokenUsage: tokenUsage
            )
        }
        return VibeviewerModel.FilteredUsageHistory(totalCount: dto.totalUsageEventsCount ?? 0, events: events)
    }

    public func fetchTeamFreeUsageCents(teamId: Int, userId: Int, cookieHeader: String) async throws -> Int {
        let dto: CursorTeamSpendResponse = try await self.performRequest(
            CursorGetTeamSpendAPI(
                teamId: teamId,
                page: 1,
                // pageSize is hardcoded to 100
                sortBy: "name",
                sortDirection: "asc",
                cookieHeader: cookieHeader
            )
        )

        guard let me = dto.teamMemberSpend.first(where: { $0.userId == userId }) else {
            return 0
        }

        let included = me.includedSpendCents ?? 0
        let overrideDollars = me.hardLimitOverrideDollars ?? 0
        let freeCents = max(included - overrideDollars * 100, 0)
        return freeCents
    }
    
    public func fetchModelsAnalytics(
        startDate: String,
        endDate: String,
        c: String,
        cookieHeader: String
    ) async throws -> VibeviewerModel.ModelsUsageChartData {
        let dto: CursorTeamModelsAnalyticsResponse = try await self.performRequest(
            CursorTeamModelsAnalyticsAPI(
                startDate: startDate,
                endDate: endDate,
                c: c,
                cookieHeader: cookieHeader
            )
        )
        return mapToModelsUsageChartData(dto)
    }
    
    public func fetchAggregatedUsageEvents(
        teamId: Int?,
        startDate: Int64,
        cookieHeader: String
    ) async throws -> VibeviewerModel.AggregatedUsageEvents {
        let dto: CursorAggregatedUsageEventsResponse = try await self.performRequest(
            CursorAggregatedUsageEventsAPI(
                teamId: teamId,
                startDate: startDate,
                cookieHeader: cookieHeader
            )
        )
        return mapToAggregatedUsageEvents(dto)
    }
    
    public func fetchCurrentBillingCycle(cookieHeader: String) async throws -> VibeviewerModel.BillingCycle {
        let dto: CursorCurrentBillingCycleResponse = try await self.performRequest(
            CursorCurrentBillingCycleAPI(cookieHeader: cookieHeader)
        )
        return mapToBillingCycle(dto)
    }
    
    public func fetchCurrentBillingCycleMs(cookieHeader: String) async throws -> (startDateMs: String, endDateMs: String) {
        let dto: CursorCurrentBillingCycleResponse = try await self.performRequest(
            CursorCurrentBillingCycleAPI(cookieHeader: cookieHeader)
        )
        return (startDateMs: dto.startDateEpochMillis, endDateMs: dto.endDateEpochMillis)
    }
    
    public func fetchModelsUsageChartFromEvents(
        startDateMs: String,
        endDateMs: String,
        userId: Int,
        cookieHeader: String
    ) async throws -> VibeviewerModel.ModelsUsageChartData {
        // 一次性获取 700 条数据（7 页，每页 100 条）
        var allEvents: [VibeviewerModel.UsageEvent] = []
        let maxPages = 7
        
        // 并发获取所有页面的数据
        try await withThrowingTaskGroup(of: (page: Int, history: VibeviewerModel.FilteredUsageHistory).self) { group in
            for page in 1...maxPages {
                group.addTask {
                    let history = try await self.fetchFilteredUsageEvents(
                        startDateMs: startDateMs,
                        endDateMs: endDateMs,
                        userId: userId,
                        page: page,
                        cookieHeader: cookieHeader
                    )
                    return (page: page, history: history)
                }
            }
            
            // 收集所有结果并按页码排序
            var results: [(page: Int, history: VibeviewerModel.FilteredUsageHistory)] = []
            for try await result in group {
                results.append(result)
            }
            results.sort { $0.page < $1.page }
            
            // 合并所有事件
            for result in results {
                allEvents.append(contentsOf: result.history.events)
            }
        }
        
        // 转换为 ModelsUsageChartData
        return convertEventsToModelsUsageChart(events: allEvents, startDateMs: startDateMs, endDateMs: endDateMs)
    }
    
    /// 映射当前计费周期 DTO 到领域模型
    private func mapToBillingCycle(_ dto: CursorCurrentBillingCycleResponse) -> VibeviewerModel.BillingCycle {
        let startDate = Date.fromMillisecondsString(dto.startDateEpochMillis) ?? Date()
        let endDate = Date.fromMillisecondsString(dto.endDateEpochMillis) ?? Date()
        return VibeviewerModel.BillingCycle(
            startDate: startDate,
            endDate: endDate
        )
    }
    
    /// 映射聚合使用事件 DTO 到领域模型
    private func mapToAggregatedUsageEvents(_ dto: CursorAggregatedUsageEventsResponse) -> VibeviewerModel.AggregatedUsageEvents {
        let aggregations = dto.aggregations.map { agg in
            VibeviewerModel.ModelAggregation(
                modelIntent: agg.modelIntent,
                inputTokens: Int(agg.inputTokens ?? "0") ?? 0,
                outputTokens: Int(agg.outputTokens ?? "0") ?? 0,
                cacheWriteTokens: Int(agg.cacheWriteTokens ?? "0") ?? 0,
                cacheReadTokens: Int(agg.cacheReadTokens ?? "0") ?? 0,
                totalCents: agg.totalCents
            )
        }
        
        return VibeviewerModel.AggregatedUsageEvents(
            aggregations: aggregations,
            totalInputTokens: Int(dto.totalInputTokens) ?? 0,
            totalOutputTokens: Int(dto.totalOutputTokens) ?? 0,
            totalCacheWriteTokens: Int(dto.totalCacheWriteTokens) ?? 0,
            totalCacheReadTokens: Int(dto.totalCacheReadTokens) ?? 0,
            totalCostCents: dto.totalCostCents
        )
    }
    
    /// 映射模型分析 DTO 到业务层柱状图数据
    private func mapToModelsUsageChartData(_ dto: CursorTeamModelsAnalyticsResponse) -> VibeviewerModel.ModelsUsageChartData {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        
        // 将 DTO 数据转换为字典，方便查找
        var dataDict: [String: VibeviewerModel.ModelsUsageChartData.DataPoint] = [:]
        for item in dto.data {
            let dateLabel = formatDateLabelForChart(from: item.date)
            let modelUsages = item.modelBreakdown
                .map { (modelName, stats) in
                    VibeviewerModel.ModelsUsageChartData.ModelUsage(
                        modelName: modelName,
                        requests: Int(stats.requests)
                    )
                }
                .sorted { $0.requests > $1.requests }
            
            dataDict[item.date] = VibeviewerModel.ModelsUsageChartData.DataPoint(
                date: item.date,
                dateLabel: dateLabel,
                modelUsages: modelUsages
            )
        }
        
        // 生成最近7天的日期范围
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var allDates: [Date] = []
        
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                allDates.append(date)
            }
        }
        
        // 补足缺失的日期
        let dataPoints = allDates.map { date -> VibeviewerModel.ModelsUsageChartData.DataPoint in
            let dateString = formatter.string(from: date)
            
            // 如果该日期有数据，使用现有数据；否则创建空数据点
            if let existingData = dataDict[dateString] {
                return existingData
            } else {
                let dateLabel = formatDateLabelForChart(from: dateString)
                return VibeviewerModel.ModelsUsageChartData.DataPoint(
                    date: dateString,
                    dateLabel: dateLabel,
                    modelUsages: []
                )
            }
        }
        
        return VibeviewerModel.ModelsUsageChartData(dataPoints: dataPoints)
    }
    
    /// 将 YYYY-MM-DD 格式的日期字符串转换为 MM/dd 格式的图表标签
    private func formatDateLabelForChart(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let labelFormatter = DateFormatter()
        labelFormatter.locale = .current
        labelFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        labelFormatter.dateFormat = "MM/dd"
        return labelFormatter.string(from: date)
    }
    
    /// 将使用事件列表转换为模型使用量图表数据
    /// - Parameters:
    ///   - events: 使用事件列表
    ///   - startDateMs: 开始日期（毫秒时间戳）
    ///   - endDateMs: 结束日期（毫秒时间戳）
    /// - Returns: 模型使用量图表数据（确保至少7天）
    private func convertEventsToModelsUsageChart(
        events: [VibeviewerModel.UsageEvent],
        startDateMs: String,
        endDateMs: String
    ) -> VibeviewerModel.ModelsUsageChartData {
        let formatter = DateFormatter()
        formatter.locale = .current
        // 使用本地时区按“自然日”分组，避免凌晨时段被算到前一天（UTC）里
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        
        // 解析开始和结束日期
        guard let startMs = Int64(startDateMs),
              let endMs = Int64(endDateMs) else {
            return VibeviewerModel.ModelsUsageChartData(dataPoints: [])
        }
        
        let startDate = Date(timeIntervalSince1970: TimeInterval(startMs) / 1000.0)
        let originalEndDate = Date(timeIntervalSince1970: TimeInterval(endMs) / 1000.0)
        let calendar = Calendar.current
        
        // 为了避免 X 轴出现“未来一天”的空数据（例如今天是 24 号却出现 25 号），
        // 这里将用于生成日期刻度的结束日期截断到“今天 00:00”，
        // 但事件本身的时间范围仍然由后端返回的数据决定。
        let startOfToday = calendar.startOfDay(for: Date())
        let endDate: Date = originalEndDate > startOfToday ? startOfToday : originalEndDate
        
        // 生成日期范围内的所有日期（从 startDate 到 endDate，均为自然日）
        var allDates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            allDates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        // 如果数据不足7天，从今天往前补足7天
        if allDates.count < 7 {
            let today = calendar.startOfDay(for: Date())
            allDates = []
            for i in (0..<7).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    allDates.append(date)
                }
            }
        }
        
        // 按日期分组统计每个模型的请求次数
        // dateString -> modelName -> requestCount
        var dateModelStats: [String: [String: Int]] = [:]
        
        // 初始化所有日期
        for date in allDates {
            let dateString = formatter.string(from: date)
            dateModelStats[dateString] = [:]
        }
        
        // 统计事件
        for event in events {
            guard let eventMs = Int64(event.occurredAtMs) else { continue }
            let eventDate = Date(timeIntervalSince1970: TimeInterval(eventMs) / 1000.0)
            let dateString = formatter.string(from: eventDate)
            
            // 如果日期在范围内，统计
            if dateModelStats[dateString] != nil {
                let modelName = event.modelName
                let currentCount = dateModelStats[dateString]?[modelName] ?? 0
                dateModelStats[dateString]?[modelName] = currentCount + event.requestCostCount
            }
        }
        
        // 转换为 DataPoint 数组
        let dataPoints = allDates.map { date -> VibeviewerModel.ModelsUsageChartData.DataPoint in
            let dateString = formatter.string(from: date)
            let dateLabel = formatDateLabelForChart(from: dateString)
            
            let modelStats = dateModelStats[dateString] ?? [:]
            let modelUsages = modelStats
                .map { (modelName, requests) in
                    VibeviewerModel.ModelsUsageChartData.ModelUsage(
                        modelName: modelName,
                        requests: requests
                    )
                }
                .sorted { $0.requests > $1.requests } // 按请求数降序排序
            
            return VibeviewerModel.ModelsUsageChartData.DataPoint(
                date: dateString,
                dateLabel: dateLabel,
                modelUsages: modelUsages
            )
        }
        
        return VibeviewerModel.ModelsUsageChartData(dataPoints: dataPoints)
    }

}

private extension DefaultCursorService {
    static func parseCents(fromDollarString s: String) -> Int {
        // "$0.04" -> 4
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let idx = trimmed.firstIndex(where: { ($0 >= "0" && $0 <= "9") || $0 == "." }) else { return 0 }
        let numberPart = trimmed[idx...]
        guard let value = Double(numberPart) else { return 0 }
        return Int((value * 100.0).rounded())
    }
    
    static func calculateRequestCount(from tokenUsage: CursorTokenUsage) -> Int {
        // 基于 token 使用情况计算请求次数
        // 如果有 output tokens 或 input tokens，说明有实际的请求
        let hasOutputTokens = (tokenUsage.outputTokens ?? 0) > 0
        let hasInputTokens = (tokenUsage.inputTokens ?? 0) > 0
        
        if hasOutputTokens || hasInputTokens {
            // 如果有 token 使用，至少算作 1 次请求
            return 1
        } else {
            // 如果没有 token 使用，可能是缓存读取或其他类型的请求
            return 1
        }
    }
}
