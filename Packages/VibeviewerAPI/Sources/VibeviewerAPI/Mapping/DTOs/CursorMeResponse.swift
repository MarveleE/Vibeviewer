import Foundation

struct CursorMeResponse: Decodable, Sendable {
    let authId: String
    let userId: Int
    let email: String
    let workosId: String
    let teamId: Int

    init(authId: String, userId: Int, email: String, workosId: String, teamId: Int) {
        self.authId = authId
        self.userId = userId
        self.email = email
        self.workosId = workosId
        self.teamId = teamId
    }
}
