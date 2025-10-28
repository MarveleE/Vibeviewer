import Foundation

@Observable
public class DashboardSnapshot: Codable, Equatable {
    // 用户邮箱
    public let email: String
    /// 当前月总请求数(包含计划内请求 + 计划外请求(Billing))
    public let totalRequestsAllModels: Int
    /// 当前月已用花费
    public let spendingCents: Int
    /// 当前月预算上限
    public let hardLimitDollars: Int
    /// 当前用量历史
    public let usageEvents: [UsageEvent]
    /// 今日请求次数（由外部在获取 usageEvents 后计算并注入）
    public let requestToday: Int
    /// 昨日请求次数（由外部在获取 usageEvents 后计算并注入）
    public let requestYestoday: Int
    /// 使用情况摘要
    public let usageSummary: UsageSummary?
    /// 团队计划下个人可用的免费额度（分）。仅 Team Plan 生效
    public let freeUsageCents: Int
    /// 用户分析数据
    public let userAnalytics: UserAnalytics?

    public init(
        email: String,
        totalRequestsAllModels: Int,
        spendingCents: Int,
        hardLimitDollars: Int,
        usageEvents: [UsageEvent] = [],
        requestToday: Int = 0,
        requestYestoday: Int = 0,
        usageSummary: UsageSummary? = nil,
        freeUsageCents: Int = 0,
        userAnalytics: UserAnalytics? = nil
    ) {
        self.email = email
        self.totalRequestsAllModels = totalRequestsAllModels
        self.spendingCents = spendingCents
        self.hardLimitDollars = hardLimitDollars
        self.usageEvents = usageEvents
        self.requestToday = requestToday
        self.requestYestoday = requestYestoday
        self.usageSummary = usageSummary
        self.freeUsageCents = freeUsageCents
        self.userAnalytics = userAnalytics
    }

    private enum CodingKeys: String, CodingKey {
        case email
        case totalRequestsAllModels
        case spendingCents
        case hardLimitDollars
        case usageEvents
        case requestToday
        case requestYestoday
        case usageSummary
        case freeUsageCents
        case userAnalytics
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.email = try container.decode(String.self, forKey: .email)
        self.totalRequestsAllModels = try container.decode(Int.self, forKey: .totalRequestsAllModels)
        self.spendingCents = try container.decode(Int.self, forKey: .spendingCents)
        self.hardLimitDollars = try container.decode(Int.self, forKey: .hardLimitDollars)
        self.requestToday = try container.decode(Int.self, forKey: .requestToday)           
        self.requestYestoday = try container.decode(Int.self, forKey: .requestYestoday)
        self.usageEvents = try container.decode([UsageEvent].self, forKey: .usageEvents)
        self.usageSummary = try? container.decode(UsageSummary.self, forKey: .usageSummary)
        self.freeUsageCents = (try? container.decode(Int.self, forKey: .freeUsageCents)) ?? 0
        self.userAnalytics = try? container.decode(UserAnalytics.self, forKey: .userAnalytics)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.email, forKey: .email)
        try container.encode(self.totalRequestsAllModels, forKey: .totalRequestsAllModels)
        try container.encode(self.spendingCents, forKey: .spendingCents)
        try container.encode(self.hardLimitDollars, forKey: .hardLimitDollars)
        try container.encode(self.usageEvents, forKey: .usageEvents)
        try container.encode(self.requestToday, forKey: .requestToday)
        try container.encode(self.requestYestoday, forKey: .requestYestoday)
        if let usageSummary = self.usageSummary {
            try container.encode(usageSummary, forKey: .usageSummary)
        }
        if self.freeUsageCents > 0 {
            try container.encode(self.freeUsageCents, forKey: .freeUsageCents)
        }
        if let userAnalytics = self.userAnalytics {
            try container.encode(userAnalytics, forKey: .userAnalytics)
        }
    }

    /// 计算 plan + onDemand 的总消耗金额（以分为单位）
    public var totalUsageCents: Int {
        guard let usageSummary = usageSummary else {
            return spendingCents
        }
        
        let planUsed = usageSummary.individualUsage.plan.used
        let onDemandUsed = usageSummary.individualUsage.onDemand?.used ?? 0
        let freeUsage = freeUsageCents
        
        return planUsed + onDemandUsed + freeUsage
    }

    public static func == (lhs: DashboardSnapshot, rhs: DashboardSnapshot) -> Bool {
        lhs.email == rhs.email &&
            lhs.totalRequestsAllModels == rhs.totalRequestsAllModels &&
            lhs.spendingCents == rhs.spendingCents &&
            lhs.hardLimitDollars == rhs.hardLimitDollars &&
            lhs.usageSummary == rhs.usageSummary &&
            lhs.freeUsageCents == rhs.freeUsageCents &&
            lhs.userAnalytics == rhs.userAnalytics
    }
}
