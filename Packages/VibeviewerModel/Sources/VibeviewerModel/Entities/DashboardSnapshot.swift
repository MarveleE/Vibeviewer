import Foundation

@Observable
public class DashboardSnapshot: Codable, Equatable {
    // 用户邮箱
    public let email: String
    /// 当前月已用请求数
    public let planRequestsUsed: Int
    /// 当前月计划内可用请求数
    public let planIncludeRequestCount: Int
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

    public init(
        email: String,
        planRequestsUsed: Int,
        planIncludeRequestCount: Int,
        totalRequestsAllModels: Int,
        spendingCents: Int,
        hardLimitDollars: Int,
        usageEvents: [UsageEvent] = [],
        requestToday: Int = 0,
        requestYestoday: Int = 0
    ) {
        self.email = email
        self.planRequestsUsed = planRequestsUsed
        self.planIncludeRequestCount = planIncludeRequestCount
        self.totalRequestsAllModels = totalRequestsAllModels
        self.spendingCents = spendingCents
        self.hardLimitDollars = hardLimitDollars
        self.usageEvents = usageEvents
        self.requestToday = requestToday
        self.requestYestoday = requestYestoday
    }

    private enum CodingKeys: String, CodingKey {
        case email
        case planRequestsUsed
        case planIncludeRequestCount
        case totalRequestsAllModels
        case spendingCents
        case hardLimitDollars
        case requestToday
        case requestYestoday
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.email = try container.decode(String.self, forKey: .email)
        self.planRequestsUsed = try container.decode(Int.self, forKey: .planRequestsUsed)
        self.planIncludeRequestCount = (try? container.decode(Int.self, forKey: .planIncludeRequestCount)) ?? 0
        self.totalRequestsAllModels = try container.decode(Int.self, forKey: .totalRequestsAllModels)
        self.spendingCents = try container.decode(Int.self, forKey: .spendingCents)
        self.hardLimitDollars = try container.decode(Int.self, forKey: .hardLimitDollars)
        self.requestToday = try container.decode(Int.self, forKey: .requestToday)
        self.requestYestoday = try container.decode(Int.self, forKey: .requestYestoday)
        self.usageEvents = []
        // usageEvents  不参与持久化解码，运行期内由 UI 拉取后写入
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.email, forKey: .email)
        try container.encode(self.planRequestsUsed, forKey: .planRequestsUsed)
        try container.encode(self.planIncludeRequestCount, forKey: .planIncludeRequestCount)
        try container.encode(self.totalRequestsAllModels, forKey: .totalRequestsAllModels)
        try container.encode(self.spendingCents, forKey: .spendingCents)
        try container.encode(self.hardLimitDollars, forKey: .hardLimitDollars)
        try container.encode(self.requestToday, forKey: .requestToday)
        try container.encode(self.requestYestoday, forKey: .requestYestoday)
        // usageEvents不参与持久化编码
    }

    public static func == (lhs: DashboardSnapshot, rhs: DashboardSnapshot) -> Bool {
        lhs.email == rhs.email &&
            lhs.planRequestsUsed == rhs.planRequestsUsed &&
            lhs.planIncludeRequestCount == rhs.planIncludeRequestCount &&
            lhs.totalRequestsAllModels == rhs.totalRequestsAllModels &&
            lhs.spendingCents == rhs.spendingCents &&
            lhs.hardLimitDollars == rhs.hardLimitDollars
    }
}
