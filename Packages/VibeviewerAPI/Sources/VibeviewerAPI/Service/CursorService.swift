import Foundation
import Moya
import VibeviewerModel

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
            if individualOnDemand.used > 0 || individualOnDemand.limit > 0 {
                return VibeviewerModel.OnDemandUsage(
                    used: individualOnDemand.used,
                    limit: individualOnDemand.limit,
                    remaining: individualOnDemand.remaining
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
            if teamOnDemand.used > 0 || teamOnDemand.limit > 0 {
                return VibeviewerModel.TeamUsage(
                    onDemand: VibeviewerModel.OnDemandUsage(
                        used: teamOnDemand.used,
                        limit: teamOnDemand.limit,
                        remaining: teamOnDemand.remaining
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
    
    /// 映射模型分析 DTO 到业务层柱状图数据
    private func mapToModelsUsageChartData(_ dto: CursorTeamModelsAnalyticsResponse) -> VibeviewerModel.ModelsUsageChartData {
        let dataPoints = dto.data.map { item -> VibeviewerModel.ModelsUsageChartData.DataPoint in
            // 将日期从 YYYY-MM-DD 格式转换为 MM/dd 格式的标签
            let dateLabel = formatDateLabelForChart(from: item.date)
            
            // 将模型使用量字典转换为数组，按请求数降序排序
            let modelUsages = item.modelBreakdown
                .map { (modelName, stats) in
                    VibeviewerModel.ModelsUsageChartData.ModelUsage(
                        modelName: modelName,
                        requests: Int(stats.requests)
                    )
                }
                .sorted { $0.requests > $1.requests } // 按请求数降序排序
            
            return VibeviewerModel.ModelsUsageChartData.DataPoint(
                date: item.date,
                dateLabel: dateLabel,
                modelUsages: modelUsages
            )
        }
        return VibeviewerModel.ModelsUsageChartData(dataPoints: dataPoints)
    }
    
    /// 将 YYYY-MM-DD 格式的日期字符串转换为 MM/dd 格式的图表标签
    private func formatDateLabelForChart(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let labelFormatter = DateFormatter()
        labelFormatter.locale = Locale(identifier: "en_US_POSIX")
        labelFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        labelFormatter.dateFormat = "MM/dd"
        return labelFormatter.string(from: date)
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
