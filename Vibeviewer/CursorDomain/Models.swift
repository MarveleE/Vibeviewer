import Foundation

// MARK: - Credentials & Persistence Models

struct CursorCredentials: Codable, Sendable {
    let userId: Int
    let workosId: String
    let email: String
    let teamId: Int
    let cookieHeader: String
}

// MARK: - API Models

struct CursorMeResponse: Decodable, Sendable {
    let authId: String
    let userId: Int
    let email: String
    let workosId: String
    let teamId: Int
}

struct CursorModelUsage: Decodable, Sendable {
    let numRequests: Int
    let numRequestsTotal: Int
    let numTokens: Int
    let maxRequestUsage: Int?
    let maxTokenUsage: Int?
}

struct CursorUsageResponse: Decodable, Sendable {
    let models: [String: CursorModelUsage]
    let startOfMonth: String

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var tempModels: [String: CursorModelUsage] = [:]
        var start: String = ""
        for key in container.allKeys {
            if key.stringValue == "startOfMonth" {
                start = try container.decode(String.self, forKey: key)
            } else {
                if let usage = try? container.decode(CursorModelUsage.self, forKey: key) {
                    tempModels[key.stringValue] = usage
                }
            }
        }
        self.models = tempModels
        self.startOfMonth = start
    }
}

struct TeamMemberSpend: Decodable, Sendable {
    let userId: Int
    let email: String
    let role: String
    let spendCents: Int?
    let fastPremiumRequests: Int?
    let hardLimitOverrideDollars: Int?
}

struct TeamSpendResponse: Decodable, Sendable {
    let teamMemberSpend: [TeamMemberSpend]
    let subscriptionCycleStart: String
    let totalMembers: Int
    let totalPages: Int
    let totalByRole: [RoleCount]

    struct RoleCount: Decodable, Sendable {
        let role: String
        let count: Int
    }
}

// MARK: - UI Aggregate State

struct CursorDashboardSnapshot: Sendable {
    let email: String
    let planRequestsUsed: Int
    let totalRequestsAllModels: Int
    let spendingCents: Int
    let hardLimitDollars: Int
}


