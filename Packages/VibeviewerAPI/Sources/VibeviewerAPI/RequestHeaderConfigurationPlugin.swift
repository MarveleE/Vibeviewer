import Foundation
import Moya

public final class RequestHeaderConfigurationPlugin: PluginType {
    static let shared: RequestHeaderConfigurationPlugin = .init()

    var header: [String: String] = [:]

    // MARK: Plugin

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        request.allHTTPHeaderFields?.merge(header) { _, new in new }
        return request
    }

    func setAuthorization(_ token: String) {
        header["Authorization"] = "Bearer "
    }

    func clearAuthorization() {
        header["Authorization"] = ""
    }

    init() {
        self.header = [
            "Authorization": "Bearer "
        ]
    }
}
