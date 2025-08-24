import Foundation

public struct CursorMeResponse: Decodable, Sendable {
    public let authId: String
    public let userId: Int
    public let email: String
    public let workosId: String
    public let teamId: Int

    public init(authId: String, userId: Int, email: String, workosId: String, teamId: Int) {
        self.authId = authId
        self.userId = userId
        self.email = email
        self.workosId = workosId
        self.teamId = teamId
    }
}
