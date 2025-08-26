import Foundation

struct CursorUsageResponse: Decodable, Sendable {
    let models: [String: CursorModelUsage]
    let startOfMonth: Date

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var tempModels: [String: CursorModelUsage] = [:]
        var start: Date?
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for key in container.allKeys {
            if key.stringValue == "startOfMonth" {
                let dateString = try container.decode(String.self, forKey: key)
                if let date = isoFormatter.date(from: dateString) {
                    start = date
                } else {
                    // 兼容无毫秒的情况
                    let fallbackFormatter = ISO8601DateFormatter()
                    fallbackFormatter.formatOptions = [.withInternetDateTime]
                    guard let fallbackDate = fallbackFormatter.date(from: dateString) else {
                        throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "startOfMonth 不是有效的 ISO8601 日期字符串: \(dateString)")
                    }
                    start = fallbackDate
                }
            } else {
                if let usage = try? container.decode(CursorModelUsage.self, forKey: key) {
                    tempModels[key.stringValue] = usage
                }
            }
        }
        guard let startOfMonth = start else {
            throw DecodingError.keyNotFound(DynamicCodingKeys(stringValue: "startOfMonth")!, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "缺少 startOfMonth 字段或格式错误"))
        }
        self.models = tempModels
        self.startOfMonth = startOfMonth
    }
}
