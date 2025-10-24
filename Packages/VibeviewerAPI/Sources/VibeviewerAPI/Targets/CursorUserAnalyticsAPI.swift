import Foundation
import Moya
import VibeviewerModel

struct CursorUserAnalyticsAPI: DecodableTargetType {
    typealias ResultType = CursorUserAnalyticsResponse

    let teamId: Int
    let userId: Int
    let startDateMs: String
    let endDateMs: String
    private let cookieHeader: String?

    var baseURL: URL { APIConfig.baseURL }
    var path: String { "/api/dashboard/get-user-analytics" }
    var method: Moya.Method { .post }
    var task: Task {
        let params: [String: Any] = [
            "teamId": self.teamId,
            "userId": self.userId,
            "startDate": self.startDateMs,
            "endDate": self.endDateMs
        ]
        return .requestParameters(parameters: params, encoding: JSONEncoding.default)
    }

    var headers: [String: String]? { APIHeadersBuilder.jsonHeaders(cookieHeader: self.cookieHeader) }
    var sampleData: Data {
        Data("""
        {
            "dailyMetrics": [],
            "period": {
                "startDate": "1761148800000",
                "endDate": "1761235200000"
            },
            "totalApplyLines": 0,
            "totalTabsAccepted": 0
        }
        """.utf8)
    }

    init(teamId: Int, userId: Int, startDateMs: String, endDateMs: String, cookieHeader: String?) {
        self.teamId = teamId
        self.userId = userId
        self.startDateMs = startDateMs
        self.endDateMs = endDateMs
        self.cookieHeader = cookieHeader
    }
}

