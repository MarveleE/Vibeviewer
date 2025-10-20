import Foundation
import Moya
import VibeviewerModel

struct CursorGetMeAPI: DecodableTargetType {
    typealias ResultType = CursorMeResponse

    var baseURL: URL { APIConfig.baseURL }
    var path: String { "/api/dashboard/get-me" }
    var method: Moya.Method { .get }
    var task: Task { .requestPlain }
    var headers: [String: String]? { APIHeadersBuilder.jsonHeaders(cookieHeader: self.cookieHeader) }
    var sampleData: Data {
        Data("{\"authId\":\"\",\"userId\":0,\"email\":\"\",\"workosId\":\"\",\"teamId\":0,\"isEnterpriseUser\":false}".utf8)
    }

    private let cookieHeader: String?
    init(cookieHeader: String?) { self.cookieHeader = cookieHeader }
}
