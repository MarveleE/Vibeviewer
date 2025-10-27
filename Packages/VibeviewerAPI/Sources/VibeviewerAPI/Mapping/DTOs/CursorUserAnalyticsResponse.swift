import Foundation

/// Cursor API 用户分析响应 DTO
struct CursorUserAnalyticsResponse: Codable, Sendable, Equatable {
    let dailyMetrics: [CursorDailyMetric]
    let period: CursorAnalyticsPeriod
    let applyLinesRank: Int?
    let tabsAcceptedRank: Int?
    let totalTeamMembers: Int?
    let totalApplyLines: Int?
    let teamAverageApplyLines: Int?
    let totalTabsAccepted: Int?
    let teamAverageTabsAccepted: Int?
    let totalMembersInTeam: Int?
}

/// Cursor API 每日指标 DTO
struct CursorDailyMetric: Codable, Sendable, Equatable {
    let date: String
    let activeUsers: Int?
    let linesAdded: Int?
    let linesDeleted: Int?
    let acceptedLinesAdded: Int?
    let acceptedLinesDeleted: Int?
    let totalApplies: Int?
    let totalAccepts: Int?
    let totalRejects: Int?
    let totalTabsShown: Int?
    let totalTabsAccepted: Int?
    let chatRequests: Int?
    let agentRequests: Int?
    let cmdkUsages: Int?
    let subscriptionIncludedReqs: Int?
    let usageBasedReqs: Int?
    let modelUsage: [CursorModelUsageCount]?
    let extensionUsage: [CursorExtensionUsageCount]?
    let tabExtensionUsage: [CursorExtensionUsageCount]?
    let clientVersionUsage: [CursorClientVersionUsageCount]?
}

/// Cursor API 模型使用计数 DTO
struct CursorModelUsageCount: Codable, Sendable, Equatable {
    let name: String
    let count: Int
}

/// Cursor API 扩展使用计数 DTO
struct CursorExtensionUsageCount: Codable, Sendable, Equatable {
    let name: String?
    let count: Int
}

/// Cursor API 客户端版本使用计数 DTO
struct CursorClientVersionUsageCount: Codable, Sendable, Equatable {
    let name: String
    let count: Int
}

/// Cursor API 分析周期 DTO
struct CursorAnalyticsPeriod: Codable, Sendable, Equatable {
    let startDate: String
    let endDate: String
}

