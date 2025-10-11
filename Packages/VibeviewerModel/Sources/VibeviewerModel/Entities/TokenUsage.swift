import Foundation

public struct TokenUsage: Codable, Sendable, Equatable {
    public let outputTokens: Int?
    public let inputTokens: Int?
    public let totalCents: Double
    public let cacheWriteTokens: Int?
    public let cacheReadTokens: Int?

    public var totalTokens: Int {
        return (outputTokens ?? 0) + (inputTokens ?? 0) + (cacheWriteTokens ?? 0) + (cacheReadTokens ?? 0)
    }

    public init(
        outputTokens: Int?,
        inputTokens: Int?,
        totalCents: Double,
        cacheWriteTokens: Int?,
        cacheReadTokens: Int?
    ) {
        self.outputTokens = outputTokens
        self.inputTokens = inputTokens
        self.totalCents = totalCents
        self.cacheWriteTokens = cacheWriteTokens
        self.cacheReadTokens = cacheReadTokens
    }
}
