import Foundation

// MARK: - Chart Type Enum

/// 图表类型枚举
public enum ChartType: String, CaseIterable, Sendable {
    case usage = "Usage"
    case modelUsage = "Model Usage"
    case tabAccept = "Tab Accept"
    case agentLineChanges = "Agent Lines"
}

// MARK: - User Analytics

/// 用户分析数据 - 包含四种图表数据
public struct UserAnalytics: Codable, Sendable, Equatable {
    /// Usage 柱状图数据
    public let usageChart: UsageChartData
    /// Model Usage 饼图数据
    public let modelUsageChart: ModelUsageChartData
    /// Tab Accept 柱状图数据
    public let tabAcceptChart: TabAcceptChartData
    /// Agent Line Changes 折线图数据
    public let agentLineChangesChart: AgentLineChangesChartData
    
    public init(
        usageChart: UsageChartData,
        modelUsageChart: ModelUsageChartData,
        tabAcceptChart: TabAcceptChartData,
        agentLineChangesChart: AgentLineChangesChartData
    ) {
        self.usageChart = usageChart
        self.modelUsageChart = modelUsageChart
        self.tabAcceptChart = tabAcceptChart
        self.agentLineChangesChart = agentLineChangesChart
    }
}

// MARK: - Usage Chart Data

/// Usage 柱状图数据
public struct UsageChartData: Codable, Sendable, Equatable {
    /// 数据点列表
    public let dataPoints: [DataPoint]
    
    public init(dataPoints: [DataPoint]) {
        self.dataPoints = dataPoints
    }
    
    /// 单个数据点
    public struct DataPoint: Codable, Sendable, Equatable {
        /// 原始日期（毫秒时间戳字符串）
        public let date: String
        /// 格式化后的日期标签（MM/dd）
        public let dateLabel: String
        /// 订阅包含的请求数
        public let subscriptionReqs: Int
        /// 基于使用量的请求数
        public let usageBasedReqs: Int
        /// 总使用次数
        public var totalValue: Int {
            subscriptionReqs + usageBasedReqs
        }
        
        public init(date: String, dateLabel: String, subscriptionReqs: Int, usageBasedReqs: Int) {
            self.date = date
            self.dateLabel = dateLabel
            self.subscriptionReqs = subscriptionReqs
            self.usageBasedReqs = usageBasedReqs
        }
    }
}

// MARK: - Model Usage Chart Data

/// Model Usage 饼图数据（所有日期总和）
public struct ModelUsageChartData: Codable, Sendable, Equatable {
    /// 模型分布列表
    public let modelDistribution: [ModelShare]
    
    public init(modelDistribution: [ModelShare]) {
        self.modelDistribution = modelDistribution
    }
    
    /// 模型占比
    public struct ModelShare: Codable, Sendable, Equatable, Identifiable {
        /// 唯一标识符
        public let id: String
        /// 模型名称
        public let modelName: String
        /// 使用次数
        public let count: Int
        /// 占比百分比（0-100）
        public let percentage: Double
        
        public init(id: String, modelName: String, count: Int, percentage: Double) {
            self.id = id
            self.modelName = modelName
            self.count = count
            self.percentage = percentage
        }
    }
}

// MARK: - Tab Accept Chart Data

/// Tab Accept 柱状图数据（每天）
public struct TabAcceptChartData: Codable, Sendable, Equatable {
    /// 数据点列表
    public let dataPoints: [DataPoint]
    
    public init(dataPoints: [DataPoint]) {
        self.dataPoints = dataPoints
    }
    
    /// 单个数据点
    public struct DataPoint: Codable, Sendable, Equatable {
        /// 原始日期（毫秒时间戳字符串）
        public let date: String
        /// 格式化后的日期标签（MM/dd）
        public let dateLabel: String
        /// 接受的 Tab 数量
        public let acceptedCount: Int
        
        public init(date: String, dateLabel: String, acceptedCount: Int) {
            self.date = date
            self.dateLabel = dateLabel
            self.acceptedCount = acceptedCount
        }
    }
}

// MARK: - Agent Line Changes Chart Data

/// Agent Line Changes 折线图数据（双Y轴）
public struct AgentLineChangesChartData: Codable, Sendable, Equatable {
    /// 数据点列表
    public let dataPoints: [DataPoint]
    
    public init(dataPoints: [DataPoint]) {
        self.dataPoints = dataPoints
    }
    
    /// 单个数据点
    public struct DataPoint: Codable, Sendable, Equatable {
        /// 原始日期（毫秒时间戳字符串）
        public let date: String
        /// 格式化后的日期标签（MM/dd）
        public let dateLabel: String
        /// 建议的总行数（linesAdded + linesDeleted）
        public let suggestedLines: Int
        /// 接受的总行数（acceptedLinesAdded + acceptedLinesDeleted）
        public let acceptedLines: Int
        
        public init(date: String, dateLabel: String, suggestedLines: Int, acceptedLines: Int) {
            self.date = date
            self.dateLabel = dateLabel
            self.suggestedLines = suggestedLines
            self.acceptedLines = acceptedLines
        }
    }
}
