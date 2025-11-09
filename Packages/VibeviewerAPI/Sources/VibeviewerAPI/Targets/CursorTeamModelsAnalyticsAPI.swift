import Foundation
import Moya

struct CursorTeamModelsAnalyticsAPI: DecodableTargetType {
    typealias ResultType = CursorTeamModelsAnalyticsResponse
    
    let startDate: String
    let endDate: String
    let c: String
    private let cookieHeader: String?
    
    var baseURL: URL { APIConfig.baseURL }
    var path: String { "/api/v2/analytics/team/models" }
    var method: Moya.Method { .get }
    var task: Task {
        let params: [String: Any] = [
            "startDate": self.startDate,
            "endDate": self.endDate,
            "c": self.c
        ]
        return .requestParameters(parameters: params, encoding: URLEncoding.default)
    }
    
    var headers: [String: String]? { APIHeadersBuilder.basicHeaders(cookieHeader: self.cookieHeader) }
    var sampleData: Data {
        Data("{}".utf8)
    }
    
    init(startDate: String, endDate: String, c: String, cookieHeader: String?) {
        self.startDate = startDate
        self.endDate = endDate
        self.c = c
        self.cookieHeader = cookieHeader
    }
}

