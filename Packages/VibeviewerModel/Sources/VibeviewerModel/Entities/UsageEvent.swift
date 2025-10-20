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
    public let cursorTokenFee: Double
    public let tokenUsage: TokenUsage?

    public var brand: AIModelBrands {
        AIModelBrands.brand(for: self.modelName)
    }
    
    /// 计算实际费用显示（美元格式）
    public var calculatedCostDisplay: String {
        let totalCents = (tokenUsage?.totalCents ?? 0.0) + cursorTokenFee
        let dollars = totalCents / 100.0
        return String(format: "$%.2f", dollars)
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
        cursorTokenFee: Double = 0.0,
        tokenUsage: TokenUsage? = nil
    ) {
        self.occurredAtMs = occurredAtMs
        self.modelName = modelName
        self.kind = kind
        self.requestCostCount = requestCostCount
        self.usageCostDisplay = usageCostDisplay
        self.usageCostCents = usageCostCents
        self.isTokenBased = isTokenBased
        self.userDisplayName = userDisplayName
        self.cursorTokenFee = cursorTokenFee
        self.tokenUsage = tokenUsage
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
        case cursorTokenFee
        case tokenUsage
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
        self.cursorTokenFee = (try? container.decode(Double.self, forKey: .cursorTokenFee)) ?? 0.0
        self.tokenUsage = try container.decodeIfPresent(TokenUsage.self, forKey: .tokenUsage)
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
        try container.encode(self.cursorTokenFee, forKey: .cursorTokenFee)
        try container.encodeIfPresent(self.tokenUsage, forKey: .tokenUsage)
    }
}
