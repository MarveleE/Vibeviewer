import Foundation

struct CursorTokenUsage: Decodable, Sendable, Equatable {
    let outputTokens: Int?
    let inputTokens: Int?
    let totalCents: Double?
    let cacheWriteTokens: Int?
    let cacheReadTokens: Int?

    init(
        outputTokens: Int?,
        inputTokens: Int?,
        totalCents: Double?,
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

struct CursorFilteredUsageEvent: Decodable, Sendable, Equatable {
    let timestamp: String
    let model: String
    let kind: String
    let requestsCosts: Double?
    let usageBasedCosts: String
    let isTokenBasedCall: Bool
    let owningUser: String
    let cursorTokenFee: Double
    let tokenUsage: CursorTokenUsage

    init(
        timestamp: String,
        model: String,
        kind: String,
        requestsCosts: Double?,
        usageBasedCosts: String,
        isTokenBasedCall: Bool,
        owningUser: String,
        cursorTokenFee: Double,
        tokenUsage: CursorTokenUsage
    ) {
        self.timestamp = timestamp
        self.model = model
        self.kind = kind
        self.requestsCosts = requestsCosts
        self.usageBasedCosts = usageBasedCosts
        self.isTokenBasedCall = isTokenBasedCall
        self.owningUser = owningUser
        self.cursorTokenFee = cursorTokenFee
        self.tokenUsage = tokenUsage
    }
}
