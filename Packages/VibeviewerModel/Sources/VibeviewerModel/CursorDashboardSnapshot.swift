import Foundation

public struct CursorDashboardSnapshot: Codable, Sendable {
    public let email: String
    public let planRequestsUsed: Int
    public let totalRequestsAllModels: Int
    public let spendingCents: Int
    public let hardLimitDollars: Int

    public init(
        email: String,
        planRequestsUsed: Int,
        totalRequestsAllModels: Int,
        spendingCents: Int,
        hardLimitDollars: Int
    ) {
        self.email = email
        self.planRequestsUsed = planRequestsUsed
        self.totalRequestsAllModels = totalRequestsAllModels
        self.spendingCents = spendingCents
        self.hardLimitDollars = hardLimitDollars
    }
}
