import Foundation

struct CursorModelUsage: Decodable, Sendable {
    let numRequests: Int
    let numRequestsTotal: Int
    let numTokens: Int
    let maxRequestUsage: Int?
    let maxTokenUsage: Int?

    init(numRequests: Int, numRequestsTotal: Int, numTokens: Int, maxRequestUsage: Int?, maxTokenUsage: Int?) {
        self.numRequests = numRequests
        self.numRequestsTotal = numRequestsTotal
        self.numTokens = numTokens
        self.maxRequestUsage = maxRequestUsage
        self.maxTokenUsage = maxTokenUsage
    }
}
