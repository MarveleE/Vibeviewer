import Foundation

struct CursorModelUsage: Decodable, Sendable {
    let numTokens: Int
    let maxTokenUsage: Int?

    init(numTokens: Int, maxTokenUsage: Int?) {
        self.numTokens = numTokens
        self.maxTokenUsage = maxTokenUsage
    }
}
