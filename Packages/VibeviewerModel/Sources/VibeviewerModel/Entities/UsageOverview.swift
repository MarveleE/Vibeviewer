import Foundation

public struct UsageOverview: Sendable, Equatable {
    public struct ModelUsage: Sendable, Equatable {
        public let modelName: String
        public let requestsUsed: Int
        public let totalRequests: Int

        public init(modelName: String, requestsUsed: Int, totalRequests: Int) {
            self.modelName = modelName
            self.requestsUsed = requestsUsed
            self.totalRequests = totalRequests
        }
    }

    public let startOfMonthMs: String
    public let models: [String: ModelUsage]

    public init(startOfMonthMs: String, models: [String: ModelUsage]) {
        self.startOfMonthMs = startOfMonthMs
        self.models = models
    }
}
