import Foundation

/// 模型用量信息 - 用于仪表板展示各个模型的详细使用情况
public struct ModelUsageInfo: Sendable, Equatable, Codable {
    /// 模型名称
    public let modelName: String
    /// 输入 token 数
    public let inputTokens: Int
    /// 输出 token 数
    public let outputTokens: Int
    /// 缓存写入 token 数
    public let cacheWriteTokens: Int
    /// 缓存读取 token 数
    public let cacheReadTokens: Int
    /// 该模型的总成本（美分）
    public let costCents: Double
    
    public init(
        modelName: String,
        inputTokens: Int,
        outputTokens: Int,
        cacheWriteTokens: Int,
        cacheReadTokens: Int,
        costCents: Double
    ) {
        self.modelName = modelName
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheWriteTokens = cacheWriteTokens
        self.cacheReadTokens = cacheReadTokens
        self.costCents = costCents
    }
    
    /// 从 ModelAggregation 转换
    public init(from aggregation: ModelAggregation) {
        self.modelName = aggregation.modelIntent
        self.inputTokens = aggregation.inputTokens
        self.outputTokens = aggregation.outputTokens
        self.cacheWriteTokens = aggregation.cacheWriteTokens
        self.cacheReadTokens = aggregation.cacheReadTokens
        self.costCents = aggregation.totalCents
    }
    
    /// 总 token 数（不含缓存）
    public var totalTokens: Int {
        inputTokens + outputTokens
    }
    
    /// 总 token 数（含缓存）
    public var totalTokensWithCache: Int {
        inputTokens + outputTokens + cacheWriteTokens + cacheReadTokens
    }
    
    /// 格式化成本显示（如 "$1.23"）
    public var formattedCost: String {
        String(format: "$%.2f", costCents / 100.0)
    }
}

/// 模型用量汇总 - 用于仪表板展示所有模型的用量概览
public struct ModelsUsageSummary: Sendable, Equatable, Codable {
    /// 各个模型的用量信息
    public let models: [ModelUsageInfo]
    /// 总输入 token 数
    public let totalInputTokens: Int
    /// 总输出 token 数
    public let totalOutputTokens: Int
    /// 总缓存写入 token 数
    public let totalCacheWriteTokens: Int
    /// 总缓存读取 token 数
    public let totalCacheReadTokens: Int
    /// 总成本（美分）
    public let totalCostCents: Double
    
    public init(
        models: [ModelUsageInfo],
        totalInputTokens: Int,
        totalOutputTokens: Int,
        totalCacheWriteTokens: Int,
        totalCacheReadTokens: Int,
        totalCostCents: Double
    ) {
        self.models = models
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
        self.totalCacheWriteTokens = totalCacheWriteTokens
        self.totalCacheReadTokens = totalCacheReadTokens
        self.totalCostCents = totalCostCents
    }
    
    /// 从 AggregatedUsageEvents 转换
    public init(from aggregated: AggregatedUsageEvents) {
        self.models = aggregated.aggregations.map { ModelUsageInfo(from: $0) }
        self.totalInputTokens = aggregated.totalInputTokens
        self.totalOutputTokens = aggregated.totalOutputTokens
        self.totalCacheWriteTokens = aggregated.totalCacheWriteTokens
        self.totalCacheReadTokens = aggregated.totalCacheReadTokens
        self.totalCostCents = aggregated.totalCostCents
    }
    
    /// 总 token 数（不含缓存）
    public var totalTokens: Int {
        totalInputTokens + totalOutputTokens
    }
    
    /// 总 token 数（含缓存）
    public var totalTokensWithCache: Int {
        totalInputTokens + totalOutputTokens + totalCacheWriteTokens + totalCacheReadTokens
    }
    
    /// 格式化总成本显示（如 "$1.23"）
    public var formattedTotalCost: String {
        String(format: "$%.2f", totalCostCents / 100.0)
    }
    
    /// 按成本降序排序的模型列表
    public var modelsSortedByCost: [ModelUsageInfo] {
        models.sorted { $0.costCents > $1.costCents }
    }
    
    /// 按 token 使用量降序排序的模型列表
    public var modelsSortedByTokens: [ModelUsageInfo] {
        models.sorted { $0.totalTokens > $1.totalTokens }
    }
}

