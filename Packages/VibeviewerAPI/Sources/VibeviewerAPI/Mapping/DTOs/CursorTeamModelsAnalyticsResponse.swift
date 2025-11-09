import Foundation

/// Cursor API 团队模型分析响应 DTO
public struct CursorTeamModelsAnalyticsResponse: Codable, Sendable, Equatable {
    public let meta: [Meta]
    public let data: [DataItem]
    
    public init(meta: [Meta], data: [DataItem]) {
        self.meta = meta
        self.data = data
    }
}

/// 元数据信息
public struct Meta: Codable, Sendable, Equatable {
    public let name: String
    public let type: String
    
    public init(name: String, type: String) {
        self.name = name
        self.type = type
    }
}

/// 数据项
public struct DataItem: Codable, Sendable, Equatable {
    public let date: String
    public let modelBreakdown: [String: ModelStats]
    
    enum CodingKeys: String, CodingKey {
        case date
        case modelBreakdown = "model_breakdown"
    }
    
    public init(date: String, modelBreakdown: [String: ModelStats]) {
        self.date = date
        self.modelBreakdown = modelBreakdown
    }
}

/// 模型统计信息
public struct ModelStats: Codable, Sendable, Equatable {
    public let requests: UInt64
    public let users: UInt64?
    
    public init(requests: UInt64, users: UInt64) {
        self.requests = requests
        self.users = users
    }
}

