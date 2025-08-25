import SwiftUI
import VibeviewerLoginUI

@MainActor
struct ActionButtonsView: View {
    let isLoading: Bool
    let isLoggedIn: Bool
    let onRefresh: () -> Void
    let onLogin: () -> Void
    let onLogout: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if isLoading {
                ProgressView()
            } else {
                Button("刷新") { onRefresh() }
            }

            if !isLoggedIn {
                Button("登录") { onLogin() }
            } else {
                Button("退出登录") { onLogout() }
            }
            Button("设置") { onSettings() }
        }
    }
}


