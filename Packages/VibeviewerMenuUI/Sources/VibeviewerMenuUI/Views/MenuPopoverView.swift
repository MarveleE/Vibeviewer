import Observation
import SwiftUI
import VibeviewerAPI
import VibeviewerAppEnvironment
import VibeviewerLoginUI
import VibeviewerModel
import VibeviewerSettingsUI
import VibeviewerCore
import VibeviewerShareUI

@MainActor
public struct MenuPopoverView: View {
    @Environment(\.loginService) private var loginService
    @Environment(\.cursorStorage) private var storage
    @Environment(\.loginWindowManager) private var loginWindow
    @Environment(\.settingsWindowManager) private var settingsWindow
    @Environment(\.dashboardRefreshService) private var refresher
    @Environment(AppSettings.self) private var appSettings
    @Environment(AppSession.self) private var session

    @Environment(\.colorScheme) private var colorScheme

    enum ViewState: Equatable {
        case loading
        case loaded
        case error(String)
    }

    public init() {}

    @State private var state: ViewState = .loading
    @State private var isLoggingIn: Bool = false
    @State private var loginError: String?

    public var body: some View {
        @Bindable var appSettings = appSettings

        VStack(alignment: .leading, spacing: 16) {
            UsageHeaderView { action in
                switch action {
                case .dashboard:
                    self.openDashboard()
                }
            }

            if isLoggingIn {
                loginLoadingView
            } else if let snapshot = self.session.snapshot {
                if let loginError {
                    // 出错时只展示错误视图，不展示旧的 snapshot 内容
                    DashboardErrorView(
                        message: loginError,
                        onRetry: { manualRefresh() }
                    )
                } else {
                let isProSeriesUser = snapshot.usageSummary?.membershipType.isProSeries == true

                if !isProSeriesUser {
                    MetricsView(metric: .billing(snapshot.billingMetrics))

                    if let free = snapshot.freeUsageMetrics {
                        MetricsView(metric: .free(free))
                    }

                    if let onDemandMetrics = snapshot.onDemandMetrics {
                        MetricsView(metric: .onDemand(onDemandMetrics))
                    }
                    
                    Divider().opacity(0.5)
                }

                UsageEventView(events: self.session.snapshot?.usageEvents ?? [])
                
                if let modelsUsageChart = self.session.snapshot?.modelsUsageChart {
                    Divider().opacity(0.5)
                    
                    ModelsUsageBarChartView(data: modelsUsageChart)
                }

                Divider().opacity(0.5)

                TotalCreditsUsageView(snapshot: snapshot)
                
                Divider().opacity(0.5)

                    MenuFooterView(onRefresh: {
                        manualRefresh()
                    })
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                loginButtonView
                    
                    if let loginError {
                        DashboardErrorView(
                            message: loginError,
                            onRetry: nil
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background {
            ZStack {
                Color(hex: colorScheme == .dark ? "1F1E1E" : "F9F9F9")
                Circle()
                    .fill(Color(hex: colorScheme == .dark ? "354E48" : "F2A48B"))
                    .padding(80)
                    .blur(radius: 100)
            }
            .cornerRadiusWithCorners(32 - 4)
        }
        .padding(session.credentials != nil ? 4 : 0)
    }

    private var loginButtonView: some View {
        UnloginView(
            onWebLogin: {
            loginWindow.show(onCookieCaptured: { cookie in
                    self.performLogin(with: cookie)
                })
            },
            onCookieLogin: { cookie in
                self.performLogin(with: cookie)
        }
        )
    }

    private func openDashboard() {
        NSWorkspace.shared.open(URL(string: "https://cursor.com/dashboard?tab=usage")!)
    }
    
    private var loginLoadingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Logging in…")
                .font(.app(.satoshiBold, size: 16))
            
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Fetching your latest usage data, this may take a few seconds.")
                    .font(.app(.satoshiMedium, size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .maxFrame(true, false, alignment: .leading)
    }
    
    private func performLogin(with cookieHeader: String) {
        Task { @MainActor in
            self.loginError = nil
            self.isLoggingIn = true
            defer { self.isLoggingIn = false }
            
            do {
                try await self.loginService.login(with: cookieHeader)
            } catch LoginServiceError.fetchAccountFailed {
                self.loginError = "Failed to fetch account info. Please check your cookie and try again."
            } catch LoginServiceError.saveCredentialsFailed {
                self.loginError = "Failed to save credentials locally. Please try again."
            } catch LoginServiceError.initialRefreshFailed {
                self.loginError = "Failed to load dashboard data. Please try again later."
            } catch {
                self.loginError = "Login failed. Please try again."
            }
        }
    }
    
    private func manualRefresh() {
        Task { @MainActor in
            guard self.session.credentials != nil else {
                self.loginError = "You need to login before refreshing dashboard data."
                return
            }
            
            self.loginError = nil
            self.isLoggingIn = true
            defer { self.isLoggingIn = false }
            
            // 使用后台刷新服务的公共方法进行刷新
            await self.refresher.refreshNow()
            
            // 如果刷新后完全没有 snapshot，则认为刷新失败并展示错误
            if self.session.snapshot == nil {
                self.loginError = "Failed to refresh dashboard data. Please try again later."
            }
        }
    }
}
