import Foundation
import Moya
import VibeviewerModel

struct CursorTeamSpendAPI: DecodableTargetType {
    typealias ResultType = TeamSpendResponse

    private let teamId: Int
    private let cookieHeader: String?

    var baseURL: URL { APIConfig.baseURL }
    var path: String { "/api/dashboard/get-team-spend" }
    var method: Moya.Method { .post }
    var task: Task { .requestJSONEncodable(["teamId": self.teamId]) }
    var headers: [String: String]? { APIHeadersBuilder.jsonHeaders(cookieHeader: self.cookieHeader) }
    var sampleData: Data {
        Data(
            "{\"teamMemberSpend\":[],\"subscriptionCycleStart\":\"\",\"totalMembers\":0,\"totalPages\":0,\"totalByRole\":[]}"
                .utf8
        )
    }

    init(teamId: Int, cookieHeader: String?) {
        self.teamId = teamId
        self.cookieHeader = cookieHeader
    }
}
