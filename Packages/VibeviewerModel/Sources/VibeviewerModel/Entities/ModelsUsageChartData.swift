import Foundation

/// 模型使用量柱状图数据
public struct ModelsUsageChartData: Codable, Sendable, Equatable {
    /// 数据点列表
    public let dataPoints: [DataPoint]
    
    public init(dataPoints: [DataPoint]) {
        self.dataPoints = dataPoints
    }
    
    /// 单个数据点
    public struct DataPoint: Codable, Sendable, Equatable {
        /// 原始日期（YYYY-MM-DD 格式）
        public let date: String
        /// 格式化后的日期标签（MM/dd）
        public let dateLabel: String
        /// 各模型的使用量列表
        public let modelUsages: [ModelUsage]
        /// 总使用次数（所有模型的总和）
        public var totalValue: Int {
            modelUsages.reduce(0) { $0 + $1.requests }
        }
        
        public init(date: String, dateLabel: String, modelUsages: [ModelUsage]) {
            self.date = date
            self.dateLabel = dateLabel
            self.modelUsages = modelUsages
        }
    }
    
    /// 单个模型的使用量
    public struct ModelUsage: Codable, Sendable, Equatable {
        /// 模型名称
        public let modelName: String
        /// 请求数
        public let requests: Int
        
        public init(modelName: String, requests: Int) {
            self.modelName = modelName
            self.requests = requests
        }
    }
}

