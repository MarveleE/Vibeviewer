import Foundation

public struct UsageEvent: Codable, Sendable, Equatable {
    public let occurredAtMs: String
    public let modelName: String
    public let kind: String
    public let requestCostCount: Int
    public let usageCostDisplay: String
    /// 花费（分）——用于数值计算与累加
    public let usageCostCents: Int
    public let isTokenBased: Bool
    public let userDisplayName: String
    public let teamDisplayName: String?

    public var brand: AIModelBrands {
        AIModelBrands.brand(for: self.modelName)
    }

    public init(
        occurredAtMs: String,
        modelName: String,
        kind: String,
        requestCostCount: Int,
        usageCostDisplay: String,
        usageCostCents: Int = 0,
        isTokenBased: Bool,
        userDisplayName: String,
        teamDisplayName: String?
    ) {
        self.occurredAtMs = occurredAtMs
        self.modelName = modelName
        self.kind = kind
        self.requestCostCount = requestCostCount
        self.usageCostDisplay = usageCostDisplay
        self.usageCostCents = usageCostCents
        self.isTokenBased = isTokenBased
        self.userDisplayName = userDisplayName
        self.teamDisplayName = teamDisplayName
    }

    private enum CodingKeys: String, CodingKey {
        case occurredAtMs
        case modelName
        case kind
        case requestCostCount
        case usageCostDisplay
        case usageCostCents
        case isTokenBased
        case userDisplayName
        case teamDisplayName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.occurredAtMs = try container.decode(String.self, forKey: .occurredAtMs)
        self.modelName = try container.decode(String.self, forKey: .modelName)
        self.kind = try container.decode(String.self, forKey: .kind)
        self.requestCostCount = try container.decode(Int.self, forKey: .requestCostCount)
        self.usageCostDisplay = try container.decode(String.self, forKey: .usageCostDisplay)
        self.usageCostCents = (try? container.decode(Int.self, forKey: .usageCostCents)) ?? 0
        self.isTokenBased = try container.decode(Bool.self, forKey: .isTokenBased)
        self.userDisplayName = try container.decode(String.self, forKey: .userDisplayName)
        self.teamDisplayName = try container.decodeIfPresent(String.self, forKey: .teamDisplayName)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.occurredAtMs, forKey: .occurredAtMs)
        try container.encode(self.modelName, forKey: .modelName)
        try container.encode(self.kind, forKey: .kind)
        try container.encode(self.requestCostCount, forKey: .requestCostCount)
        try container.encode(self.usageCostDisplay, forKey: .usageCostDisplay)
        try container.encode(self.usageCostCents, forKey: .usageCostCents)
        try container.encode(self.isTokenBased, forKey: .isTokenBased)
        try container.encode(self.userDisplayName, forKey: .userDisplayName)
        try container.encode(self.teamDisplayName, forKey: .teamDisplayName)
    }
}
