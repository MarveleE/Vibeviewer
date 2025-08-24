import Foundation

public struct CursorModelUsage: Decodable, Sendable {
    public let numRequests: Int
    public let numRequestsTotal: Int
    public let numTokens: Int
    public let maxRequestUsage: Int?
    public let maxTokenUsage: Int?

    public init(numRequests: Int, numRequestsTotal: Int, numTokens: Int, maxRequestUsage: Int?, maxTokenUsage: Int?) {
        self.numRequests = numRequests
        self.numRequestsTotal = numRequestsTotal
        self.numTokens = numTokens
        self.maxRequestUsage = maxRequestUsage
        self.maxTokenUsage = maxTokenUsage
    }
}
