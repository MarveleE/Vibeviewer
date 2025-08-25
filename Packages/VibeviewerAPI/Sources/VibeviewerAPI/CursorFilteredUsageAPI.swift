import Foundation
import Moya
import VibeviewerModel

struct CursorFilteredUsageAPI: DecodableTargetType {
    typealias ResultType = CursorFilteredUsageResponse

    let teamId: Int
    let startDateMs: String
    let endDateMs: String
    let userId: Int
    let page: Int
    let pageSize: Int
    private let cookieHeader: String?

    var baseURL: URL { APIConfig.baseURL }
    var path: String { "/api/dashboard/get-filtered-usage-events" }
    var method: Moya.Method { .post }
    var task: Task {
        let params: [String: Any] = [
            "teamId": self.teamId,
            "startDate": self.startDateMs,
            "endDate": self.endDateMs,
            "userId": self.userId,
            "page": self.page,
            "pageSize": self.pageSize
        ]
        return .requestParameters(parameters: params, encoding: JSONEncoding.default)
    }

    var headers: [String: String]? { APIHeadersBuilder.jsonHeaders(cookieHeader: self.cookieHeader) }
    var sampleData: Data {
        Data("{\"totalUsageEventsCount\":1,\"usageEventsDisplay\":[]}".utf8)
    }

    init(teamId: Int, startDateMs: String, endDateMs: String, userId: Int, page: Int, pageSize: Int, cookieHeader: String?) {
        self.teamId = teamId
        self.startDateMs = startDateMs
        self.endDateMs = endDateMs
        self.userId = userId
        self.page = page
        self.pageSize = pageSize
        self.cookieHeader = cookieHeader
    }
}


