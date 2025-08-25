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
            if self.isLoading {
                ProgressView()
            } else {
                Button("刷新") { self.onRefresh() }
            }

            if !self.isLoggedIn {
                Button("登录") { self.onLogin() }
            } else {
                Button("退出登录") { self.onLogout() }
            }
            Button("设置") { self.onSettings() }
        }
    }
}
