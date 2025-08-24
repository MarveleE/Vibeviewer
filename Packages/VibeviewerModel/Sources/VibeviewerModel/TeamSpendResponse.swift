import Foundation

public struct TeamMemberSpend: Decodable, Sendable {
    public let userId: Int
    public let email: String
    public let role: String
    public let spendCents: Int?
    public let fastPremiumRequests: Int?
    public let hardLimitOverrideDollars: Int?

    public init(userId: Int, email: String, role: String, spendCents: Int?, fastPremiumRequests: Int?, hardLimitOverrideDollars: Int?) {
        self.userId = userId
        self.email = email
        self.role = role
        self.spendCents = spendCents
        self.fastPremiumRequests = fastPremiumRequests
        self.hardLimitOverrideDollars = hardLimitOverrideDollars
    }
}

public struct TeamSpendResponse: Decodable, Sendable {
    public let teamMemberSpend: [TeamMemberSpend]
    public let subscriptionCycleStart: String
    public let totalMembers: Int
    public let totalPages: Int
    public let totalByRole: [RoleCount]

    public struct RoleCount: Decodable, Sendable {
        public let role: String
        public let count: Int

        public init(role: String, count: Int) {
            self.role = role
            self.count = count
        }
    }

    public init(teamMemberSpend: [TeamMemberSpend], subscriptionCycleStart: String, totalMembers: Int, totalPages: Int, totalByRole: [RoleCount]) {
        self.teamMemberSpend = teamMemberSpend
        self.subscriptionCycleStart = subscriptionCycleStart
        self.totalMembers = totalMembers
        self.totalPages = totalPages
        self.totalByRole = totalByRole
    }
}
