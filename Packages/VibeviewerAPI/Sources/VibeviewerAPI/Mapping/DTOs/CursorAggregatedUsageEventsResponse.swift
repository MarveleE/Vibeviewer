import Foundation

/// Cursor API 返回的聚合使用事件响应 DTO
struct CursorAggregatedUsageEventsResponse: Decodable, Sendable, Equatable {
    let aggregations: [CursorModelAggregation]
    let totalInputTokens: String
    let totalOutputTokens: String
    let totalCacheWriteTokens: String
    let totalCacheReadTokens: String
    let totalCostCents: Double
    
    init(
        aggregations: [CursorModelAggregation],
        totalInputTokens: String,
        totalOutputTokens: String,
        totalCacheWriteTokens: String,
        totalCacheReadTokens: String,
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

/// 单个模型的聚合数据 DTO
struct CursorModelAggregation: Decodable, Sendable, Equatable {
    let modelIntent: String
    let inputTokens: String?
    let outputTokens: String?
    let cacheWriteTokens: String?
    let cacheReadTokens: String?
    let totalCents: Double
    
    init(
        modelIntent: String,
        inputTokens: String?,
        outputTokens: String?,
        cacheWriteTokens: String?,
        cacheReadTokens: String?,
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

