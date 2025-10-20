import Foundation

/// 会员类型
public enum MembershipType: String, Sendable, Equatable, Codable {
    case enterprise = "enterprise"
    case freeTrial = "free_trial"
    case pro = "pro"
    case proPlus = "pro_plus"
    case ultra = "ultra"
    case free = "free"
    
    /// 获取会员类型的显示名称
    /// - Parameters:
    ///   - subscriptionStatus: 订阅状态
    ///   - isEnterprise: 是否为企业版（用于区分 Enterprise 和 Team Plan）
    /// - Returns: 显示名称
    public func displayName(
        subscriptionStatus: SubscriptionStatus? = nil,
        isEnterprise: Bool = false
    ) -> String {
        switch self {
        case .enterprise:
            return isEnterprise ? "Enterprise" : "Team Plan"
        case .freeTrial:
            return "Pro Trial"
        case .pro:
            return subscriptionStatus == .trialing ? "Pro Trial" : "Pro Plan"
        case .proPlus:
            return subscriptionStatus == .trialing ? "Pro+ Trial" : "Pro+ Plan"
        case .ultra:
            return "Ultra Plan"
        case .free:
            return "Free Plan"
        }
    }
}

/// 订阅状态
public enum SubscriptionStatus: String, Sendable, Equatable, Codable {
    case trialing = "trialing"
    case active = "active"
    case canceled = "canceled"
    case pastDue = "past_due"
    case unpaid = "unpaid"
}

