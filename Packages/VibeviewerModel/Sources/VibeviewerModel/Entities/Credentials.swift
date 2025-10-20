import Foundation

@Observable
public class Credentials: Codable, Equatable {
    public let userId: Int
    public let workosId: String
    public let email: String
    public let teamId: Int
    public let cookieHeader: String
    public let isEnterpriseUser: Bool

    public init(userId: Int, workosId: String, email: String, teamId: Int, cookieHeader: String, isEnterpriseUser: Bool) {
        self.userId = userId
        self.workosId = workosId
        self.email = email
        self.teamId = teamId
        self.cookieHeader = cookieHeader
        self.isEnterpriseUser = isEnterpriseUser
    }

    public static func == (lhs: Credentials, rhs: Credentials) -> Bool {
        lhs.userId == rhs.userId &&
            lhs.workosId == rhs.workosId &&
            lhs.email == rhs.email &&
            lhs.teamId == rhs.teamId &&
            lhs.cookieHeader == rhs.cookieHeader &&
            lhs.isEnterpriseUser == rhs.isEnterpriseUser
    }
}
