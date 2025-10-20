import SwiftUI
import VibeviewerShareUI
import VibeviewerAppEnvironment
import VibeviewerModel
import VibeviewerSettingsUI

struct MenuFooterView: View {
    @Environment(\.dashboardRefreshService) private var refresher
    @Environment(\.settingsWindowManager) private var settingsWindow
    @Environment(AppSession.self) private var session
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                settingsWindow.show()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            // 显示会员类型徽章
            if let membershipType = session.snapshot?.usageSummary?.membershipType {
                MembershipBadge(
                    membershipType: membershipType,
                    isEnterpriseUser: session.credentials?.isEnterpriseUser ?? false
                )
            }
            
            Spacer()

            Button {
                Task {  
                    await refresher.refreshNow()
                }
            } label: {
                HStack(spacing: 4) {
                    if refresher.isRefreshing {
                        ProgressView()
                            .controlSize(.mini)
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .frame(width: 16, height: 16)
                    } 
                    Text("Refresh")
                            .font(.app(.satoshiMedium, size: 12))
                }
            }
            .buttonStyle(.vibe(Color(hex: "5B67E2").opacity(0.8)))
            .animation(.easeInOut(duration: 0.2), value: refresher.isRefreshing) 

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit")
                    .font(.app(.satoshiMedium, size: 12))
            }
            .buttonStyle(.vibe(Color(hex: "F58283").opacity(0.8)))
        }
    }
}
