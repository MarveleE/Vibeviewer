import Foundation

public struct DashboardSnapshot: Codable, Sendable, Equatable {
    public let email: String
    public let planRequestsUsed: Int
    public let totalRequestsAllModels: Int
    public let spendingCents: Int
    public let hardLimitDollars: Int
    public let usageEvents: [UsageEvent]

    public init(
        email: String,
        planRequestsUsed: Int,
        totalRequestsAllModels: Int,
        spendingCents: Int,
        hardLimitDollars: Int,
        usageEvents: [UsageEvent] = []
    ) {
        self.email = email
        self.planRequestsUsed = planRequestsUsed
        self.totalRequestsAllModels = totalRequestsAllModels
        self.spendingCents = spendingCents
        self.hardLimitDollars = hardLimitDollars
        self.usageEvents = usageEvents
    }

    private enum CodingKeys: String, CodingKey {
        case email
        case planRequestsUsed
        case totalRequestsAllModels
        case spendingCents
        case hardLimitDollars
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.email = try container.decode(String.self, forKey: .email)
        self.planRequestsUsed = try container.decode(Int.self, forKey: .planRequestsUsed)
        self.totalRequestsAllModels = try container.decode(Int.self, forKey: .totalRequestsAllModels)
        self.spendingCents = try container.decode(Int.self, forKey: .spendingCents)
        self.hardLimitDollars = try container.decode(Int.self, forKey: .hardLimitDollars)
        // usageEvents 不参与持久化解码，运行期内由 UI 拉取后写入
        self.usageEvents = []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(email, forKey: .email)
        try container.encode(planRequestsUsed, forKey: .planRequestsUsed)
        try container.encode(totalRequestsAllModels, forKey: .totalRequestsAllModels)
        try container.encode(spendingCents, forKey: .spendingCents)
        try container.encode(hardLimitDollars, forKey: .hardLimitDollars)
        // usageEvents 不参与持久化编码
    }
}


