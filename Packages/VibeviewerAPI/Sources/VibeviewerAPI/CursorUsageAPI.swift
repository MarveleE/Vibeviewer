import Foundation
import Moya
import VibeviewerModel

struct CursorUsageAPI: DecodableTargetType {
    typealias ResultType = CursorUsageResponse

    let workosUserId: String
    private let cookieHeader: String?

    var baseURL: URL { APIConfig.baseURL }
    var path: String { "/api/usage" }
    var method: Moya.Method { .get }
    var task: Task {
        .requestParameters(parameters: ["user": self.workosUserId], encoding: URLEncoding.queryString)
    }

    var headers: [String: String]? { APIHeadersBuilder.basicHeaders(cookieHeader: self.cookieHeader) }
    var sampleData: Data {
        Data(
            "{\"gpt-4\":{\"numRequests\":1,\"numRequestsTotal\":1,\"numTokens\":10,\"maxRequestUsage\":500,\"maxTokenUsage\":null},\"startOfMonth\":\"2025-08-01T00:00:00.000Z\"}"
                .utf8
        )
    }

    init(workosUserId: String, cookieHeader: String?) {
        self.workosUserId = workosUserId
        self.cookieHeader = cookieHeader
    }
}
