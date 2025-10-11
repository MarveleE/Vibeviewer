import Foundation

public struct UsageOverview: Sendable, Equatable {
    public struct ModelUsage: Sendable, Equatable {
        public let modelName: String
        /// 当前月已用 token 数
        public let tokensUsed: Int?

        public init(modelName: String, tokensUsed: Int? = nil) {
            self.modelName = modelName
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
