import Foundation

public struct CursorFilteredUsageEvent: Decodable, Sendable, Equatable {
    public let timestamp: String
    public let model: String
    public let kind: String
    public let requestsCosts: Int?
    public let usageBasedCosts: String
    public let isTokenBasedCall: Bool
    public let owningUser: String
    public let owningTeam: String

    public init(
        timestamp: String,
        model: String,
        kind: String,
        requestsCosts: Int?,
        usageBasedCosts: String,
        isTokenBasedCall: Bool,
        owningUser: String,
        owningTeam: String
    ) {
        self.timestamp = timestamp
        self.model = model
        self.kind = kind
        self.requestsCosts = requestsCosts
        self.usageBasedCosts = usageBasedCosts
        self.isTokenBasedCall = isTokenBasedCall
        self.owningUser = owningUser
        self.owningTeam = owningTeam
    }
}


