import Foundation

struct CursorTeamMemberSpend: Decodable, Sendable {
    let userId: Int
    let email: String
    let role: String
    let spendCents: Int?
    let fastPremiumRequests: Int?
    let hardLimitOverrideDollars: Int?

    init(
        userId: Int,
        email: String,
        role: String,
        spendCents: Int?,
        fastPremiumRequests: Int?,
        hardLimitOverrideDollars: Int?
    ) {
        self.userId = userId
        self.email = email
        self.role = role
        self.spendCents = spendCents
        self.fastPremiumRequests = fastPremiumRequests
        self.hardLimitOverrideDollars = hardLimitOverrideDollars
    }
}

struct CursorTeamSpendResponse: Decodable, Sendable {
    let teamMemberSpend: [CursorTeamMemberSpend]
    let subscriptionCycleStart: String
    let totalMembers: Int
    let totalPages: Int
    let totalByRole: [RoleCount]

    struct RoleCount: Decodable, Sendable {
        let role: String
        let count: Int

        init(role: String, count: Int) {
            self.role = role
            self.count = count
        }
    }

    init(
        teamMemberSpend: [CursorTeamMemberSpend],
        subscriptionCycleStart: String,
        totalMembers: Int,
        totalPages: Int,
        totalByRole: [RoleCount]
    ) {
        self.teamMemberSpend = teamMemberSpend
        self.subscriptionCycleStart = subscriptionCycleStart
        self.totalMembers = totalMembers
        self.totalPages = totalPages
        self.totalByRole = totalByRole
    }
}
