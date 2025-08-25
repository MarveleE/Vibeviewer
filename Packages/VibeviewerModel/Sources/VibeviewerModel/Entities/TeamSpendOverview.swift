import Foundation

public struct TeamSpendOverview: Sendable, Equatable {
    public struct Member: Sendable, Equatable {
        public let userId: Int
        public let email: String
        public let role: String
        public let spendCents: Int
        public let fastPremiumRequests: Int
        public let hardLimitOverrideDollars: Int

        public init(
            userId: Int,
            email: String,
            role: String,
            spendCents: Int,
            fastPremiumRequests: Int,
            hardLimitOverrideDollars: Int
        ) {
            self.userId = userId
            self.email = email
            self.role = role
            self.spendCents = spendCents
            self.fastPremiumRequests = fastPremiumRequests
            self.hardLimitOverrideDollars = hardLimitOverrideDollars
        }
    }

    public struct RoleCount: Sendable, Equatable {
        public let role: String
        public let count: Int

        public init(role: String, count: Int) {
            self.role = role
            self.count = count
        }
    }

    public let subscriptionCycleStartMs: String
    public let members: [Member]
    public let totalMembers: Int
    public let totalPages: Int
    public let totalByRole: [RoleCount]

    public init(
        subscriptionCycleStartMs: String,
        members: [Member],
        totalMembers: Int,
        totalPages: Int,
        totalByRole: [RoleCount]
    ) {
        self.subscriptionCycleStartMs = subscriptionCycleStartMs
        self.members = members
        self.totalMembers = totalMembers
        self.totalPages = totalPages
        self.totalByRole = totalByRole
    }
}


