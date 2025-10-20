import Foundation

struct CursorUsageSummaryResponse: Decodable, Sendable, Equatable {
    let billingCycleStart: String
    let billingCycleEnd: String
    let membershipType: String
    let limitType: String
    let individualUsage: CursorIndividualUsage
    let teamUsage: CursorTeamUsage?
    
    init(
        billingCycleStart: String,
        billingCycleEnd: String,
        membershipType: String,
        limitType: String,
        individualUsage: CursorIndividualUsage,
        teamUsage: CursorTeamUsage? = nil
    ) {
        self.billingCycleStart = billingCycleStart
        self.billingCycleEnd = billingCycleEnd
        self.membershipType = membershipType
        self.limitType = limitType
        self.individualUsage = individualUsage
        self.teamUsage = teamUsage
    }
}

struct CursorIndividualUsage: Decodable, Sendable, Equatable {
    let plan: CursorPlanUsage
    let onDemand: CursorOnDemandUsage?
    
    init(plan: CursorPlanUsage, onDemand: CursorOnDemandUsage? = nil) {
        self.plan = plan
        self.onDemand = onDemand
    }
}

struct CursorPlanUsage: Decodable, Sendable, Equatable {
    let used: Int
    let limit: Int
    let remaining: Int
    let breakdown: CursorPlanBreakdown
    
    init(used: Int, limit: Int, remaining: Int, breakdown: CursorPlanBreakdown) {
        self.used = used
        self.limit = limit
        self.remaining = remaining
        self.breakdown = breakdown
    }
}

struct CursorPlanBreakdown: Decodable, Sendable, Equatable {
    let included: Int
    let bonus: Int
    let total: Int
    
    init(included: Int, bonus: Int, total: Int) {
        self.included = included
        self.bonus = bonus
        self.total = total
    }
}

struct CursorOnDemandUsage: Decodable, Sendable, Equatable {
    let used: Int
    let limit: Int
    let remaining: Int
    
    init(used: Int, limit: Int, remaining: Int) {
        self.used = used
        self.limit = limit
        self.remaining = remaining
    }
}

struct CursorTeamUsage: Decodable, Sendable, Equatable {
    let onDemand: CursorOnDemandUsage?
    
    init(onDemand: CursorOnDemandUsage? = nil) {
        self.onDemand = onDemand
    }
}
