import Foundation
import Moya

struct CursorTeamSpendAPI: DecodableTargetType {
    typealias ResultType = CursorTeamSpendResponse

    let teamId: Int
    let cookieHeader: String

    var baseURL: URL { APIConfig.baseURL }
    var path: String { "/api/dashboard/get-team-spend" }
    var method: Moya.Method { .post }
    var sampleData: Data { Data() }
    var task: Task {
        .requestParameters(parameters: [
            "teamId": self.teamId
        ], encoding: JSONEncoding.default)
    }

    var headers: [String: String]? { APIHeadersBuilder.jsonHeaders(cookieHeader: self.cookieHeader) }
}
