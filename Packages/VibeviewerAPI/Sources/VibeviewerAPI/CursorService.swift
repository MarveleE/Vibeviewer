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
    func fetchMe(cookieHeader: String) async throws -> CursorMeResponse
    func fetchUsage(workosUserId: String, cookieHeader: String) async throws -> CursorUsageResponse
    func fetchTeamSpend(teamId: Int, cookieHeader: String) async throws -> TeamSpendResponse
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

    public func fetchMe(cookieHeader: String) async throws -> CursorMeResponse {
        try await self.performRequest(CursorGetMeAPI(cookieHeader: cookieHeader))
    }

    public func fetchUsage(workosUserId: String, cookieHeader: String) async throws -> CursorUsageResponse {
        try await self.performRequest(CursorUsageAPI(workosUserId: workosUserId, cookieHeader: cookieHeader))
    }

    public func fetchTeamSpend(teamId: Int, cookieHeader: String) async throws -> TeamSpendResponse {
        try await self.performRequest(CursorTeamSpendAPI(teamId: teamId, cookieHeader: cookieHeader))
    }
}
