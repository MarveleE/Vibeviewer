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
    func fetchFilteredUsageEvents(
        teamId: Int,
        startDateMs: String,
        endDateMs: String,
        userId: Int,
        page: Int,
        pageSize: Int,
        cookieHeader: String
    ) async throws -> VibeviewerModel.FilteredUsageHistory
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
            teamId: dto.teamId,
            cookieHeader: cookieHeader
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
            if dto.individualUsage.onDemand.used > 0 || dto.individualUsage.onDemand.limit > 0 {
                return VibeviewerModel.OnDemandUsage(
                    used: dto.individualUsage.onDemand.used,
                    limit: dto.individualUsage.onDemand.limit,
                    remaining: dto.individualUsage.onDemand.remaining
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
            if dto.teamUsage.onDemand.used > 0 || dto.teamUsage.onDemand.limit > 0 {
                return VibeviewerModel.TeamUsage(
                    onDemand: VibeviewerModel.OnDemandUsage(
                        used: dto.teamUsage.onDemand.used,
                        limit: dto.teamUsage.onDemand.limit,
                        remaining: dto.teamUsage.onDemand.remaining
                    )
                )
            }
            return nil
        }()
        
        return VibeviewerModel.UsageSummary(
            billingCycleStart: billingCycleStart,
            billingCycleEnd: billingCycleEnd,
            membershipType: dto.membershipType,
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
        let events: [VibeviewerModel.UsageEvent] = dto.usageEventsDisplay.map { e in
            let tokenUsage = VibeviewerModel.TokenUsage(
                outputTokens: e.tokenUsage.outputTokens,
                inputTokens: e.tokenUsage.inputTokens,
                totalCents: e.tokenUsage.totalCents,
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
                teamDisplayName: e.owningTeam,
                cursorTokenFee: e.cursorTokenFee,
                tokenUsage: tokenUsage
            )
        }
        return VibeviewerModel.FilteredUsageHistory(totalCount: dto.totalUsageEventsCount, events: events)
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
