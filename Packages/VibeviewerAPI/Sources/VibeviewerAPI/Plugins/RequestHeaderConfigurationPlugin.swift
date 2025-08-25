import Foundation
import Moya

final class RequestHeaderConfigurationPlugin: PluginType {
    static let shared: RequestHeaderConfigurationPlugin = .init()

    var header: [String: String] = [:]

    // MARK: Plugin

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        request.allHTTPHeaderFields?.merge(self.header) { _, new in new }
        return request
    }

    func setAuthorization(_ token: String) {
        self.header["Authorization"] = "Bearer "
    }

    func clearAuthorization() {
        self.header["Authorization"] = ""
    }

    init() {
        self.header = [
            "Authorization": "Bearer "
        ]
    }
}
