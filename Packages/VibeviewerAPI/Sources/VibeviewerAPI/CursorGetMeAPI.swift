import Foundation
import Moya
import VibeviewerModel

struct CursorGetMeAPI: DecodableTargetType {
  typealias ResultType = CursorMeResponse

  var baseURL: URL { APIConfig.baseURL }
  var path: String { "/api/dashboard/get-me" }
  var method: Moya.Method { .get }
  var task: Task { .requestPlain }
  var headers: [String: String]? { APIHeadersBuilder.jsonHeaders(cookieHeader: cookieHeader) }
  var sampleData: Data {
    Data("{\"authId\":\"\",\"userId\":0,\"email\":\"\",\"workosId\":\"\",\"teamId\":0}".utf8)
  }

  private let cookieHeader: String?
  init(cookieHeader: String?) { self.cookieHeader = cookieHeader }
}
