import SwiftUI
import VibeviewerModel
import VibeviewerShareUI

/// 会员类型徽章组件
struct MembershipBadge: View {
    let membershipType: MembershipType
    let isEnterpriseUser: Bool
    
    var body: some View {
        Text(membershipType.displayName(isEnterprise: isEnterpriseUser))
            .font(.app(.satoshiMedium, size: 12))
            .foregroundStyle(.secondary)
    }
}

#Preview {
    VStack(spacing: 12) {
        MembershipBadge(membershipType: .free, isEnterpriseUser: false)
        MembershipBadge(membershipType: .freeTrial, isEnterpriseUser: false)
        MembershipBadge(membershipType: .pro, isEnterpriseUser: false)
        MembershipBadge(membershipType: .proPlus, isEnterpriseUser: false)
        MembershipBadge(membershipType: .ultra, isEnterpriseUser: false)
        MembershipBadge(membershipType: .enterprise, isEnterpriseUser: false)
        MembershipBadge(membershipType: .enterprise, isEnterpriseUser: true)
    }
    .padding()
}

