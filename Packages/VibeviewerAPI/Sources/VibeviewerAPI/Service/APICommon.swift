import Foundation

enum APIConfig {
    static let baseURL = URL(string: "https://cursor.com")!
    static let dashboardReferer = "https://cursor.com/dashboard"
}

enum APIHeadersBuilder {
    static func jsonHeaders(cookieHeader: String?) -> [String: String] {
        var h: [String: String] = [
            "accept": "*/*",
            "content-type": "application/json",
            "origin": "https://cursor.com",
            "referer": APIConfig.dashboardReferer
        ]
        if let cookieHeader, !cookieHeader.isEmpty { h["Cookie"] = cookieHeader }
        return h
    }

    static func basicHeaders(cookieHeader: String?) -> [String: String] {
        var h: [String: String] = [
            "accept": "*/*",
            "referer": APIConfig.dashboardReferer
        ]
        if let cookieHeader, !cookieHeader.isEmpty { h["Cookie"] = cookieHeader }
        return h
    }
}
