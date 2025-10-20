import Foundation

struct CursorTeamSpendResponse: Decodable, Sendable, Equatable {
    let teamMemberSpend: [CursorTeamMemberSpend]
    let subscriptionCycleStart: String
    let totalMembers: Int
    let totalPages: Int
    let totalByRole: [CursorRoleCount]
    let nextCycleStart: String
    let limitedUserCount: Int
    let maxUserSpendCents: Int?
    let subscriptionLimitedUsers: Int
}

struct CursorTeamMemberSpend: Decodable, Sendable, Equatable {
    let userId: Int
    let email: String
    let role: String
    let hardLimitOverrideDollars: Int?
    let includedSpendCents: Int?
    let spendCents: Int?
    let fastPremiumRequests: Int?
}

struct CursorRoleCount: Decodable, Sendable, Equatable {
    let role: String
    let count: Int
}


