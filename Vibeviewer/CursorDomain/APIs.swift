import Foundation
import Moya
import GroNetworkKit

// MARK: - Targets

struct CursorGetMeAPI: DecodableTargetType {
    typealias ResultType = CursorMeResponse

    var baseURL: URL { URL(string: "https://cursor.com")! }
    var path: String { "/api/dashboard/get-me" }
    var method: Moya.Method { .get }
    var task: Task { .requestPlain }
    var headers: [String : String]? { commonHeaders }
    var sampleData: Data { Data("{\"authId\":\"\",\"userId\":0,\"email\":\"\",\"workosId\":\"\",\"teamId\":0}".utf8) }

    private let cookieHeader: String?
    init(cookieHeader: String?) { self.cookieHeader = cookieHeader }

    private var commonHeaders: [String: String] {
        var h: [String: String] = [
            "accept": "*/*",
            "content-type": "application/json",
            "origin": "https://cursor.com",
            "referer": "https://cursor.com/dashboard"
        ]
        if let cookieHeader, !cookieHeader.isEmpty {
            h["Cookie"] = cookieHeader
        }
        return h
    }
}

struct CursorUsageAPI: DecodableTargetType {
    typealias ResultType = CursorUsageResponse

    let workosUserId: String
    private let cookieHeader: String?

    var baseURL: URL { URL(string: "https://cursor.com")! }
    var path: String { "/api/usage" }
    var method: Moya.Method { .get }
    var task: Task { .requestParameters(parameters: ["user": workosUserId], encoding: URLEncoding.queryString) }
    var headers: [String : String]? { commonHeaders }
    var sampleData: Data { Data("{\"gpt-4\":{\"numRequests\":1,\"numRequestsTotal\":1,\"numTokens\":10,\"maxRequestUsage\":500,\"maxTokenUsage\":null},\"startOfMonth\":\"2025-08-01T00:00:00.000Z\"}".utf8) }

    init(workosUserId: String, cookieHeader: String?) {
        self.workosUserId = workosUserId
        self.cookieHeader = cookieHeader
    }

    private var commonHeaders: [String: String] {
        var h: [String: String] = [
            "accept": "*/*",
            "referer": "https://cursor.com/dashboard"
        ]
        if let cookieHeader, !cookieHeader.isEmpty {
            h["Cookie"] = cookieHeader
        }
        return h
    }
}

struct CursorTeamSpendAPI: DecodableTargetType {
    typealias ResultType = TeamSpendResponse

    private let teamId: Int
    private let cookieHeader: String?

    var baseURL: URL { URL(string: "https://cursor.com")! }
    var path: String { "/api/dashboard/get-team-spend" }
    var method: Moya.Method { .post }
    var task: Task { .requestJSONEncodable(["teamId": teamId]) }
    var headers: [String : String]? { commonHeaders }
    var sampleData: Data { Data("{\"teamMemberSpend\":[],\"subscriptionCycleStart\":\"\",\"totalMembers\":0,\"totalPages\":0,\"totalByRole\":[]}".utf8) }

    init(teamId: Int, cookieHeader: String?) {
        self.teamId = teamId
        self.cookieHeader = cookieHeader
    }

    private var commonHeaders: [String: String] {
        var h: [String: String] = [
            "accept": "*/*",
            "content-type": "application/json",
            "origin": "https://cursor.com",
            "referer": "https://cursor.com/dashboard"
        ]
        if let cookieHeader, !cookieHeader.isEmpty {
            h["Cookie"] = cookieHeader
        }
        return h
    }
}

// MARK: - Service

enum CursorServiceError: Error {
    case sessionExpired
}

protocol CursorNetworkClient {
    func decodableRequest<T: DecodableTargetType>(
        _ target: T,
        decodingStrategy: JSONDecoder.KeyDecodingStrategy
    ) async throws -> T.ResultType
}

struct DefaultCursorNetworkClient: CursorNetworkClient {
    init() {}

    func decodableRequest<T>(_ target: T, decodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> T.ResultType where T : DecodableTargetType {
        try await GroNetwork.decodableRequest(target, decodingStrategy: decodingStrategy)
    }
}

protocol CursorService {
    func fetchMe(cookieHeader: String) async throws -> CursorMeResponse
    func fetchUsage(workosUserId: String, cookieHeader: String) async throws -> CursorUsageResponse
    func fetchTeamSpend(teamId: Int, cookieHeader: String) async throws -> TeamSpendResponse
}

struct DefaultCursorService: CursorService {
    private let network: CursorNetworkClient
    private let decoding: JSONDecoder.KeyDecodingStrategy

    init(network: CursorNetworkClient = DefaultCursorNetworkClient(), decoding: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) {
        self.network = network
        self.decoding = decoding
    }

    private func performRequest<T: DecodableTargetType>(_ target: T) async throws -> T.ResultType {
        do {
            return try await network.decodableRequest(target, decodingStrategy: decoding)
        } catch {
            if let moyaError = error as? MoyaError,
               case let .statusCode(response) = moyaError,
               [401, 403].contains(response.statusCode) {
                throw CursorServiceError.sessionExpired
            }
            throw error
        }
    }

    func fetchMe(cookieHeader: String) async throws -> CursorMeResponse {
        try await performRequest(CursorGetMeAPI(cookieHeader: cookieHeader))
    }

    func fetchUsage(workosUserId: String, cookieHeader: String) async throws -> CursorUsageResponse {
        try await performRequest(CursorUsageAPI(workosUserId: workosUserId, cookieHeader: cookieHeader))
    }

    func fetchTeamSpend(teamId: Int, cookieHeader: String) async throws -> TeamSpendResponse {
        try await performRequest(CursorTeamSpendAPI(teamId: teamId, cookieHeader: cookieHeader))
    }
}


