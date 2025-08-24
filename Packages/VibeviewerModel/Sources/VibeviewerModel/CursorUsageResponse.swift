import Foundation

public struct CursorUsageResponse: Decodable, Sendable {
    public let models: [String: CursorModelUsage]
    public let startOfMonth: String

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var tempModels: [String: CursorModelUsage] = [:]
        var start: String = ""
        for key in container.allKeys {
            if key.stringValue == "startOfMonth" {
                start = try container.decode(String.self, forKey: key)
            } else {
                if let usage = try? container.decode(CursorModelUsage.self, forKey: key) {
                    tempModels[key.stringValue] = usage
                }
            }
        }
        self.models = tempModels
        self.startOfMonth = start
    }
}
