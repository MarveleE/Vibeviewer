import Foundation

/// 计费周期领域实体
public struct BillingCycle: Sendable, Equatable, Codable {
    /// 计费周期开始日期
    public let startDate: Date
    /// 计费周期结束日期
    public let endDate: Date
    
    public init(
        startDate: Date,
        endDate: Date
    ) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

