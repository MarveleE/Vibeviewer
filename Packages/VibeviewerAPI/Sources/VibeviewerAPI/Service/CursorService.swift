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
        teamId: Int,
        startDateMs: String,
        endDateMs: String,
        userId: Int,
        page: Int,
        pageSize: Int,
        cookieHeader: String
    ) async throws -> VibeviewerModel.FilteredUsageHistory
    func fetchUserAnalytics(
        userId: Int,
        startDateMs: String,
        endDateMs: String,
        cookieHeader: String
    ) async throws -> VibeviewerModel.UserAnalytics
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
        teamId: Int,
        startDateMs: String,
        endDateMs: String,
        userId: Int,
        page: Int,
        pageSize: Int,
        cookieHeader: String
    ) async throws -> VibeviewerModel.FilteredUsageHistory {
        let dto: CursorFilteredUsageResponse = try await self.performRequest(
            CursorFilteredUsageAPI(
                teamId: teamId,
                startDateMs: startDateMs,
                endDateMs: endDateMs,
                userId: userId,
                page: page,
                pageSize: pageSize,
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
                pageSize: 50,
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

    public func fetchUserAnalytics(
        userId: Int,
        startDateMs: String,
        endDateMs: String,
        cookieHeader: String
    ) async throws -> VibeviewerModel.UserAnalytics {
        let dto: CursorUserAnalyticsResponse = try await self.performRequest(
            CursorUserAnalyticsAPI(
                userId: userId,
                startDateMs: startDateMs,
                endDateMs: endDateMs,
                cookieHeader: cookieHeader
            )
        )
        
        // 映射每日指标
        let dailyMetrics: [VibeviewerModel.DailyMetric] = dto.dailyMetrics.map { metric in
            // 映射模型使用情况
            let modelUsage = (metric.modelUsage ?? []).map { model in
                VibeviewerModel.ModelUsageCount(name: model.name, count: model.count)
            }
            
            // 映射扩展使用情况
            let extensionUsage = (metric.extensionUsage ?? []).map { ext in
                VibeviewerModel.ExtensionUsageCount(name: ext.name, count: ext.count)
            }
            
            // 映射 Tab 扩展使用情况
            let tabExtensionUsage = (metric.tabExtensionUsage ?? []).map { ext in
                VibeviewerModel.ExtensionUsageCount(name: ext.name, count: ext.count)
            }
            
            // 映射客户端版本使用情况
            let clientVersionUsage = (metric.clientVersionUsage ?? []).map { version in
                VibeviewerModel.ClientVersionUsageCount(name: version.name, count: version.count)
            }
            
            return VibeviewerModel.DailyMetric(
                date: metric.date,
                activeUsers: metric.activeUsers,
                linesAdded: metric.linesAdded,
                linesDeleted: metric.linesDeleted,
                acceptedLinesAdded: metric.acceptedLinesAdded,
                acceptedLinesDeleted: metric.acceptedLinesDeleted,
                totalApplies: metric.totalApplies,
                totalAccepts: metric.totalAccepts,
                totalRejects: metric.totalRejects,
                totalTabsShown: metric.totalTabsShown,
                totalTabsAccepted: metric.totalTabsAccepted,
                chatRequests: metric.chatRequests,
                agentRequests: metric.agentRequests,
                cmdkUsages: metric.cmdkUsages,
                subscriptionIncludedReqs: metric.subscriptionIncludedReqs,
                modelUsage: modelUsage,
                extensionUsage: extensionUsage,
                tabExtensionUsage: tabExtensionUsage,
                clientVersionUsage: clientVersionUsage
            )
        }
        
        // 映射分析周期
        let period = VibeviewerModel.AnalyticsPeriod(
            startDate: dto.period.startDate,
            endDate: dto.period.endDate
        )
        
        return VibeviewerModel.UserAnalytics(
            dailyMetrics: dailyMetrics,
            period: period,
            applyLinesRank: dto.applyLinesRank,
            tabsAcceptedRank: dto.tabsAcceptedRank,
            totalTeamMembers: dto.totalTeamMembers,
            totalApplyLines: dto.totalApplyLines,
            teamAverageApplyLines: dto.teamAverageApplyLines,
            totalTabsAccepted: dto.totalTabsAccepted,
            teamAverageTabsAccepted: dto.teamAverageTabsAccepted,
            totalMembersInTeam: dto.totalMembersInTeam
        )
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
