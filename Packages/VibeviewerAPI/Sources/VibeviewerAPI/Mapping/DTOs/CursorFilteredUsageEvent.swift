import Foundation

struct CursorFilteredUsageEvent: Decodable, Sendable, Equatable {
    let timestamp: String
    let model: String
    let kind: String
    let requestsCosts: Int?
    let usageBasedCosts: String
    let isTokenBasedCall: Bool
    let owningUser: String
    let owningTeam: String

    init(
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


