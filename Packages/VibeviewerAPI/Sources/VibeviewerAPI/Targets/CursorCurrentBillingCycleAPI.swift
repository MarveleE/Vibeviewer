import Foundation
import Moya

struct CursorCurrentBillingCycleAPI: DecodableTargetType {
    typealias ResultType = CursorCurrentBillingCycleResponse
    
    private let cookieHeader: String?
    
    var baseURL: URL { APIConfig.baseURL }
    var path: String { "/api/dashboard/get-current-billing-cycle" }
    var method: Moya.Method { .post }
    var task: Task {
        .requestParameters(parameters: [:], encoding: JSONEncoding.default)
    }
    
    var headers: [String: String]? { APIHeadersBuilder.jsonHeaders(cookieHeader: self.cookieHeader) }
    var sampleData: Data {
        Data("""
        {
            "startDateEpochMillis": "1763891472000",
            "endDateEpochMillis": "1764496272000"
        }
        """.utf8)
    }
    
    init(cookieHeader: String?) {
        self.cookieHeader = cookieHeader
    }
}

