import Foundation

/// 用户分析数据
public struct UserAnalytics: Codable, Sendable, Equatable {
    /// 每日指标列表
    public let dailyMetrics: [DailyMetric]
    /// 统计周期
    public let period: AnalyticsPeriod
    /// 应用行数排名（可选，团队相关）
    public let applyLinesRank: Int?
    /// Tab 接受数排名（可选，团队相关）
    public let tabsAcceptedRank: Int?
    /// 团队总成员数（可选，团队相关）
    public let totalTeamMembers: Int?
    /// 用户总应用行数
    public let totalApplyLines: Int?
    /// 团队平均应用行数（可选，团队相关）
    public let teamAverageApplyLines: Int?
    /// 用户总 Tab 接受数
    public let totalTabsAccepted: Int?
    /// 团队平均 Tab 接受数（可选，团队相关）
    public let teamAverageTabsAccepted: Int?
    /// 团队中的总成员数（可选，团队相关）
    public let totalMembersInTeam: Int?
    
    public init(
        dailyMetrics: [DailyMetric],
        period: AnalyticsPeriod,
        applyLinesRank: Int? = nil,
        tabsAcceptedRank: Int? = nil,
        totalTeamMembers: Int? = nil,
        totalApplyLines: Int? = nil,
        teamAverageApplyLines: Int? = nil,
        totalTabsAccepted: Int? = nil,
        teamAverageTabsAccepted: Int? = nil,
        totalMembersInTeam: Int? = nil
    ) {
        self.dailyMetrics = dailyMetrics
        self.period = period
        self.applyLinesRank = applyLinesRank
        self.tabsAcceptedRank = tabsAcceptedRank
        self.totalTeamMembers = totalTeamMembers
        self.totalApplyLines = totalApplyLines
        self.teamAverageApplyLines = teamAverageApplyLines
        self.totalTabsAccepted = totalTabsAccepted
        self.teamAverageTabsAccepted = teamAverageTabsAccepted
        self.totalMembersInTeam = totalMembersInTeam
    }
}

/// 每日指标
public struct DailyMetric: Codable, Sendable, Equatable {
    /// 日期（毫秒时间戳字符串）
    public let date: String
    /// 活跃用户数
    public let activeUsers: Int?
    /// 添加的代码行数
    public let linesAdded: Int?
    /// 删除的代码行数
    public let linesDeleted: Int?
    /// 接受的添加行数
    public let acceptedLinesAdded: Int?
    /// 接受的删除行数
    public let acceptedLinesDeleted: Int?
    /// 总应用次数
    public let totalApplies: Int?
    /// 总接受次数
    public let totalAccepts: Int?
    /// 总拒绝次数
    public let totalRejects: Int?
    /// 显示的 Tab 总数
    public let totalTabsShown: Int?
    /// 接受的 Tab 总数
    public let totalTabsAccepted: Int?
    /// 聊天请求数
    public let chatRequests: Int?
    /// Agent 请求数
    public let agentRequests: Int?
    /// Cmd+K 使用次数
    public let cmdkUsages: Int?
    /// 订阅包含的请求数
    public let subscriptionIncludedReqs: Int?
    /// 模型使用情况
    public let modelUsage: [ModelUsageCount]
    /// 扩展使用情况
    public let extensionUsage: [ExtensionUsageCount]
    /// Tab 扩展使用情况
    public let tabExtensionUsage: [ExtensionUsageCount]
    /// 客户端版本使用情况
    public let clientVersionUsage: [ClientVersionUsageCount]
    
    public init(
        date: String,
        activeUsers: Int? = nil,
        linesAdded: Int? = nil,
        linesDeleted: Int? = nil,
        acceptedLinesAdded: Int? = nil,
        acceptedLinesDeleted: Int? = nil,
        totalApplies: Int? = nil,
        totalAccepts: Int? = nil,
        totalRejects: Int? = nil,
        totalTabsShown: Int? = nil,
        totalTabsAccepted: Int? = nil,
        chatRequests: Int? = nil,
        agentRequests: Int? = nil,
        cmdkUsages: Int? = nil,
        subscriptionIncludedReqs: Int? = nil,
        modelUsage: [ModelUsageCount] = [],
        extensionUsage: [ExtensionUsageCount] = [],
        tabExtensionUsage: [ExtensionUsageCount] = [],
        clientVersionUsage: [ClientVersionUsageCount] = []
    ) {
        self.date = date
        self.activeUsers = activeUsers
        self.linesAdded = linesAdded
        self.linesDeleted = linesDeleted
        self.acceptedLinesAdded = acceptedLinesAdded
        self.acceptedLinesDeleted = acceptedLinesDeleted
        self.totalApplies = totalApplies
        self.totalAccepts = totalAccepts
        self.totalRejects = totalRejects
        self.totalTabsShown = totalTabsShown
        self.totalTabsAccepted = totalTabsAccepted
        self.chatRequests = chatRequests
        self.agentRequests = agentRequests
        self.cmdkUsages = cmdkUsages
        self.subscriptionIncludedReqs = subscriptionIncludedReqs
        self.modelUsage = modelUsage
        self.extensionUsage = extensionUsage
        self.tabExtensionUsage = tabExtensionUsage
        self.clientVersionUsage = clientVersionUsage
    }
}

/// 模型使用计数
public struct ModelUsageCount: Codable, Sendable, Equatable {
    /// 模型名称
    public let name: String
    /// 使用次数
    public let count: Int
    
    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }
}

/// 扩展使用计数
public struct ExtensionUsageCount: Codable, Sendable, Equatable {
    /// 扩展名称（可选）
    public let name: String?
    /// 使用次数
    public let count: Int
    
    public init(name: String? = nil, count: Int) {
        self.name = name
        self.count = count
    }
}

/// 客户端版本使用计数
public struct ClientVersionUsageCount: Codable, Sendable, Equatable {
    /// 版本号
    public let name: String
    /// 使用次数
    public let count: Int
    
    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }
}

/// 分析周期
public struct AnalyticsPeriod: Codable, Sendable, Equatable {
    /// 开始日期（毫秒时间戳字符串）
    public let startDate: String
    /// 结束日期（毫秒时间戳字符串）
    public let endDate: String
    
    public init(startDate: String, endDate: String) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

