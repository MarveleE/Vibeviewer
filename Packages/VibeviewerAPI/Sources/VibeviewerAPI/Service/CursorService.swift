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
        try await GroNetwork.decodableRequest(target, decodingStrategy: decodingStrategy)
    }
}

public protocol CursorService {
    func fetchMe(cookieHeader: String) async throws -> Credentials
    func fetchUsage(workosUserId: String, cookieHeader: String) async throws -> UsageOverview
    func fetchTeamSpend(teamId: Int, cookieHeader: String) async throws -> TeamSpendOverview
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

    public func fetchUsage(workosUserId: String, cookieHeader: String) async throws -> VibeviewerModel.UsageOverview {
        let dto: CursorUsageResponse = try await self.performRequest(CursorUsageAPI(workosUserId: workosUserId, cookieHeader: cookieHeader))
        var mapped: [String: VibeviewerModel.UsageOverview.ModelUsage] = [:]
        for (name, usage) in dto.models {
            mapped[name] = .init(modelName: name, requestsUsed: usage.numRequests, totalRequests: usage.numRequestsTotal)
        }
        return VibeviewerModel.UsageOverview(startOfMonthMs: dto.startOfMonth, models: mapped)
    }

    public func fetchTeamSpend(teamId: Int, cookieHeader: String) async throws -> VibeviewerModel.TeamSpendOverview {
        let dto: CursorTeamSpendResponse = try await self.performRequest(CursorTeamSpendAPI(teamId: teamId, cookieHeader: cookieHeader))
        let members: [VibeviewerModel.TeamSpendOverview.Member] = dto.teamMemberSpend.map { m in
            .init(
                userId: m.userId,
                email: m.email,
                role: m.role,
                spendCents: m.spendCents ?? 0,
                fastPremiumRequests: m.fastPremiumRequests ?? 0,
                hardLimitOverrideDollars: m.hardLimitOverrideDollars ?? 0
            )
        }
        let roles: [VibeviewerModel.TeamSpendOverview.RoleCount] = dto.totalByRole.map { .init(role: $0.role, count: $0.count) }
        return VibeviewerModel.TeamSpendOverview(
            subscriptionCycleStartMs: dto.subscriptionCycleStart,
            members: members,
            totalMembers: dto.totalMembers,
            totalPages: dto.totalPages,
            totalByRole: roles
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
            VibeviewerModel.UsageEvent(
                occurredAtMs: e.timestamp,
                modelName: e.model,
                kind: e.kind,
                requestCostCount: e.requestsCosts ?? 0,
                usageCostDisplay: e.usageBasedCosts,
                isTokenBased: e.isTokenBasedCall,
                userDisplayName: e.owningUser,
                teamDisplayName: e.owningTeam
            )
        }
        return VibeviewerModel.FilteredUsageHistory(totalCount: dto.totalUsageEventsCount, events: events)
    }
}
