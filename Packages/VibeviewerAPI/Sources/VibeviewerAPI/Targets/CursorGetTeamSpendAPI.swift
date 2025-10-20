import Foundation
import Moya

struct CursorGetTeamSpendAPI: DecodableTargetType {
    typealias ResultType = CursorTeamSpendResponse

    let teamId: Int
    let page: Int
    let pageSize: Int
    let sortBy: String
    let sortDirection: String
    private let cookieHeader: String?

    var baseURL: URL { APIConfig.baseURL }
    var path: String { "/api/dashboard/get-team-spend" }
    var method: Moya.Method { .post }
    var task: Task {
        let params: [String: Any] = [
            "teamId": self.teamId,
            "page": self.page,
            "pageSize": self.pageSize,
            "sortBy": self.sortBy,
            "sortDirection": self.sortDirection
        ]
        return .requestParameters(parameters: params, encoding: JSONEncoding.default)
    }
    var headers: [String: String]? { APIHeadersBuilder.jsonHeaders(cookieHeader: self.cookieHeader) }
    var sampleData: Data {
        Data("{\n  \"teamMemberSpend\": [],\n  \"subscriptionCycleStart\": \"0\",\n  \"totalMembers\": 0,\n  \"totalPages\": 0,\n  \"totalByRole\": [],\n  \"nextCycleStart\": \"0\",\n  \"limitedUserCount\": 0,\n  \"maxUserSpendCents\": 0,\n  \"subscriptionLimitedUsers\": 0\n}".utf8)
    }

    init(teamId: Int, page: Int = 1, pageSize: Int = 50, sortBy: String = "name", sortDirection: String = "asc", cookieHeader: String?) {
        self.teamId = teamId
        self.page = page
        self.pageSize = pageSize
        self.sortBy = sortBy
        self.sortDirection = sortDirection
        self.cookieHeader = cookieHeader
    }
}


