import Foundation
import Moya

struct CursorAggregatedUsageEventsAPI: DecodableTargetType {
    typealias ResultType = CursorAggregatedUsageEventsResponse
    
    let teamId: Int?
    let startDate: Int64
    private let cookieHeader: String?
    
    var baseURL: URL { APIConfig.baseURL }
    var path: String { "/api/dashboard/get-aggregated-usage-events" }
    var method: Moya.Method { .post }
    var task: Task {
        var params: [String: Any] = [
            "startDate": self.startDate
        ]
        if let teamId = self.teamId {
            params["teamId"] = teamId
        }
        return .requestParameters(parameters: params, encoding: JSONEncoding.default)
    }
    
    var headers: [String: String]? { APIHeadersBuilder.jsonHeaders(cookieHeader: self.cookieHeader) }
    var sampleData: Data {
        Data("""
        {
            "aggregations": [],
            "totalInputTokens": "0",
            "totalOutputTokens": "0",
            "totalCacheWriteTokens": "0",
            "totalCacheReadTokens": "0",
            "totalCostCents": 0.0
        }
        """.utf8)
    }
    
    init(teamId: Int?, startDate: Int64, cookieHeader: String?) {
        self.teamId = teamId
        self.startDate = startDate
        self.cookieHeader = cookieHeader
    }
}

