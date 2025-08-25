import Foundation
import Moya

struct CursorTeamSpendAPI: DecodableTargetType {
    typealias ResultType = CursorTeamSpendResponse

    let teamId: Int
    let cookieHeader: String

    var baseURL: URL { APIConfig.baseURL }
    var path: String { "/api/team/spend" }
    var method: Moya.Method { .get }
    var sampleData: Data { Data() }
    var task: Task {
        .requestParameters(parameters: [
            "teamId": self.teamId
        ], encoding: URLEncoding.default)
    }
    var headers: [String: String]? { APIHeadersBuilder.basicHeaders(cookieHeader: self.cookieHeader) }
}
