import Foundation

/// 聚合使用事件的领域实体
public struct AggregatedUsageEvents: Sendable, Equatable, Codable {
    /// 按模型分组的使用聚合数据
    public let aggregations: [ModelAggregation]
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
        aggregations: [ModelAggregation],
        totalInputTokens: Int,
        totalOutputTokens: Int,
        totalCacheWriteTokens: Int,
        totalCacheReadTokens: Int,
        totalCostCents: Double
    ) {
        self.aggregations = aggregations
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
        self.totalCacheWriteTokens = totalCacheWriteTokens
        self.totalCacheReadTokens = totalCacheReadTokens
        self.totalCostCents = totalCostCents
    }
}

/// 单个模型的使用聚合数据
public struct ModelAggregation: Sendable, Equatable, Codable {
    /// 模型意图/名称（如 "claude-4.5-sonnet-thinking"）
    public let modelIntent: String
    /// 输入 token 数
    public let inputTokens: Int
    /// 输出 token 数
    public let outputTokens: Int
    /// 缓存写入 token 数
    public let cacheWriteTokens: Int
    /// 缓存读取 token 数
    public let cacheReadTokens: Int
    /// 该模型的总成本（美分）
    public let totalCents: Double
    
    public init(
        modelIntent: String,
        inputTokens: Int,
        outputTokens: Int,
        cacheWriteTokens: Int,
        cacheReadTokens: Int,
        totalCents: Double
    ) {
        self.modelIntent = modelIntent
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheWriteTokens = cacheWriteTokens
        self.cacheReadTokens = cacheReadTokens
        self.totalCents = totalCents
    }
}

