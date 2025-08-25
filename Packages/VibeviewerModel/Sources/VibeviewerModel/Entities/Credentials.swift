import Foundation

public struct Credentials: Codable, Sendable {
    public let userId: Int
    public let workosId: String
    public let email: String
    public let teamId: Int
    public let cookieHeader: String

    public init(userId: Int, workosId: String, email: String, teamId: Int, cookieHeader: String) {
        self.userId = userId
        self.workosId = workosId
        self.email = email
        self.teamId = teamId
        self.cookieHeader = cookieHeader
    }
}


