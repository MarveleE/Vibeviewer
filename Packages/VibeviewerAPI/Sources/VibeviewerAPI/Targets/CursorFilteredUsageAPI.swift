import Foundation
import Moya
import VibeviewerModel

struct CursorFilteredUsageAPI: DecodableTargetType {
    typealias ResultType = CursorFilteredUsageResponse

    let startDateMs: String
    let endDateMs: String
    let userId: Int
    let page: Int
    private let cookieHeader: String?

    var baseURL: URL { APIConfig.baseURL }
    var path: String { "/api/dashboard/get-filtered-usage-events" }
    var method: Moya.Method { .post }
    var task: Task {
        let params: [String: Any] = [
            "startDate": self.startDateMs,
            "endDate": self.endDateMs,
            "userId": self.userId,
            "page": self.page,
            "pageSize": 100
        ]
        return .requestParameters(parameters: params, encoding: JSONEncoding.default)
    }

    var headers: [String: String]? { APIHeadersBuilder.jsonHeaders(cookieHeader: self.cookieHeader) }
    var sampleData: Data {
        Data("{\"totalUsageEventsCount\":1,\"usageEventsDisplay\":[]}".utf8)
    }

    init(startDateMs: String, endDateMs: String, userId: Int, page: Int, cookieHeader: String?) {
        self.startDateMs = startDateMs
        self.endDateMs = endDateMs
        self.userId = userId
        self.page = page
        self.cookieHeader = cookieHeader
    }
}
