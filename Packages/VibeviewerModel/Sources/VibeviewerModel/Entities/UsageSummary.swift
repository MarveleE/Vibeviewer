import Foundation

public struct UsageSummary: Sendable, Equatable, Codable {
    public let billingCycleStart: Date
    public let billingCycleEnd: Date
    public let membershipType: MembershipType
    public let limitType: String
    public let individualUsage: IndividualUsage
    public let teamUsage: TeamUsage?
    
    public init(
        billingCycleStart: Date,
        billingCycleEnd: Date,
        membershipType: MembershipType,
        limitType: String,
        individualUsage: IndividualUsage,
        teamUsage: TeamUsage? = nil
    ) {
        self.billingCycleStart = billingCycleStart
        self.billingCycleEnd = billingCycleEnd
        self.membershipType = membershipType
        self.limitType = limitType
        self.individualUsage = individualUsage
        self.teamUsage = teamUsage
    }
}

public struct IndividualUsage: Sendable, Equatable, Codable {
    public let plan: PlanUsage
    public let onDemand: OnDemandUsage?
    
    public init(plan: PlanUsage, onDemand: OnDemandUsage? = nil) {
        self.plan = plan
        self.onDemand = onDemand
    }
}

public struct PlanUsage: Sendable, Equatable, Codable {
    public let used: Int
    public let limit: Int
    public let remaining: Int
    public let breakdown: PlanBreakdown
    
    public init(used: Int, limit: Int, remaining: Int, breakdown: PlanBreakdown) {
        self.used = used
        self.limit = limit
        self.remaining = remaining
        self.breakdown = breakdown
    }
}

public struct PlanBreakdown: Sendable, Equatable, Codable {
    public let included: Int
    public let bonus: Int
    public let total: Int
    
    public init(included: Int, bonus: Int, total: Int) {
        self.included = included
        self.bonus = bonus
        self.total = total
    }
}

public struct OnDemandUsage: Sendable, Equatable, Codable {
    public let used: Int
    public let limit: Int
    public let remaining: Int
    
    public init(used: Int, limit: Int, remaining: Int) {
        self.used = used
        self.limit = limit
        self.remaining = remaining
    }
}

public struct TeamUsage: Sendable, Equatable, Codable {
    public let onDemand: OnDemandUsage
    
    public init(onDemand: OnDemandUsage) {
        self.onDemand = onDemand
    }
}
