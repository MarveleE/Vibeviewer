import Foundation

public struct UsageEvent: Sendable, Equatable {
    public let occurredAtMs: String
    public let modelName: String
    public let kind: String
    public let requestCostCount: Int
    public let usageCostDisplay: String
    public let isTokenBased: Bool
    public let userDisplayName: String
    public let teamDisplayName: String

    public init(
        occurredAtMs: String,
        modelName: String,
        kind: String,
        requestCostCount: Int,
        usageCostDisplay: String,
        isTokenBased: Bool,
        userDisplayName: String,
        teamDisplayName: String
    ) {
        self.occurredAtMs = occurredAtMs
        self.modelName = modelName
        self.kind = kind
        self.requestCostCount = requestCostCount
        self.usageCostDisplay = usageCostDisplay
        self.isTokenBased = isTokenBased
        self.userDisplayName = userDisplayName
        self.teamDisplayName = teamDisplayName
    }
}
