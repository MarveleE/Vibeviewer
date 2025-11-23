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
    /// 模型使用量柱状图数据
    public let modelsUsageChart: ModelsUsageChartData?
    /// 模型用量汇总信息（仅 Pro 账号，非 Team 账号）
    public let modelsUsageSummary: ModelsUsageSummary?
    /// 当前计费周期开始时间（毫秒时间戳字符串）
    public let billingCycleStartMs: String?
    /// 当前计费周期结束时间（毫秒时间戳字符串）
    public let billingCycleEndMs: String?

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
        modelsUsageChart: ModelsUsageChartData? = nil,
        modelsUsageSummary: ModelsUsageSummary? = nil,
        billingCycleStartMs: String? = nil,
        billingCycleEndMs: String? = nil
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
        self.modelsUsageChart = modelsUsageChart
        self.modelsUsageSummary = modelsUsageSummary
        self.billingCycleStartMs = billingCycleStartMs
        self.billingCycleEndMs = billingCycleEndMs
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
        case modelsUsageChart
        case modelsUsageSummary
        case billingCycleStartMs
        case billingCycleEndMs
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
        self.modelsUsageChart = try? container.decode(ModelsUsageChartData.self, forKey: .modelsUsageChart)
        self.modelsUsageSummary = try? container.decode(ModelsUsageSummary.self, forKey: .modelsUsageSummary)
        self.billingCycleStartMs = try? container.decode(String.self, forKey: .billingCycleStartMs)
        self.billingCycleEndMs = try? container.decode(String.self, forKey: .billingCycleEndMs)
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
        if let modelsUsageChart = self.modelsUsageChart {
            try container.encode(modelsUsageChart, forKey: .modelsUsageChart)
        }
        if let modelsUsageSummary = self.modelsUsageSummary {
            try container.encode(modelsUsageSummary, forKey: .modelsUsageSummary)
        }
        if let billingCycleStartMs = self.billingCycleStartMs {
            try container.encode(billingCycleStartMs, forKey: .billingCycleStartMs)
        }
        if let billingCycleEndMs = self.billingCycleEndMs {
            try container.encode(billingCycleEndMs, forKey: .billingCycleEndMs)
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
    
    /// UI 展示用的总消耗金额（以分为单位）
    /// - 对于 Pro 系列账号（pro / proPlus / ultra），如果存在 `modelsUsageSummary`，
    ///   优先使用模型聚合总成本（基于 `ModelUsageInfo` 汇总）
    /// - 其它情况则回退到 `totalUsageCents`
    public var displayTotalUsageCents: Int {
        if
            let usageSummary,
            let modelsUsageSummary,
            usageSummary.membershipType.isProSeries
        {
            return Int(modelsUsageSummary.totalCostCents.rounded())
        }
        
        return totalUsageCents
    }

    public static func == (lhs: DashboardSnapshot, rhs: DashboardSnapshot) -> Bool {
        lhs.email == rhs.email &&
            lhs.totalRequestsAllModels == rhs.totalRequestsAllModels &&
            lhs.spendingCents == rhs.spendingCents &&
            lhs.hardLimitDollars == rhs.hardLimitDollars &&
            lhs.usageSummary == rhs.usageSummary &&
            lhs.freeUsageCents == rhs.freeUsageCents &&
            lhs.modelsUsageChart == rhs.modelsUsageChart &&
            lhs.modelsUsageSummary == rhs.modelsUsageSummary &&
            lhs.billingCycleStartMs == rhs.billingCycleStartMs &&
            lhs.billingCycleEndMs == rhs.billingCycleEndMs
    }
}
