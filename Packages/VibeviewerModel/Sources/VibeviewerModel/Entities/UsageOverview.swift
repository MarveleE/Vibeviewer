import Foundation

public struct UsageOverview: Sendable, Equatable {
    public struct ModelUsage: Sendable, Equatable {
        public let modelName: String
        /// 当前月已用请求数
        public let requestsUsed: Int
        /// 当前月总请求数(包含计划内请求 + 计划外请求(Billing))
        public let totalRequests: Int
        /// 当前月最大请求数
        public let maxRequestUsage: Int?
        /// 当前月已用 token 数
        public let tokensUsed: Int?

        public init(modelName: String, requestsUsed: Int, totalRequests: Int, maxRequestUsage: Int? = nil, tokensUsed: Int? = nil) {
            self.modelName = modelName
            self.requestsUsed = requestsUsed
            self.totalRequests = totalRequests
            self.maxRequestUsage = maxRequestUsage
            self.tokensUsed = tokensUsed
        }
    }

    public let startOfMonthMs: Date
    public let models: [ModelUsage]

    public init(startOfMonthMs: Date, models: [ModelUsage]) {
        self.startOfMonthMs = startOfMonthMs
        self.models = models
    }
}
