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
    @Environment(\.cursorService) private var service
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

    public var body: some View {
        @Bindable var appSettings = appSettings

        VStack(alignment: .leading, spacing: 16) {
            UsageHeaderView { action in
                switch action {
                case .dashboard:
                    self.openDashboard()
                case .logout:
                    Task {
                        await self.setLoggedOut()
                    }
                }
            }

            if let snapshot = self.session.snapshot {
                MetricsView(metric: .billing(snapshot.billingMetrics))

                if let free = snapshot.freeUsageMetrics {
                    MetricsView(metric: .free(free))
                }

                if let onDemandMetrics = snapshot.onDemandMetrics {
                    MetricsView(metric: .onDemand(onDemandMetrics))
                }

                // Divider().opacity(0.5)
                
                // RequestsCompareView(requestToday: self.session.snapshot?.requestToday ?? 0, requestYestoday: self.session.snapshot?.requestYestoday ?? 0)
                
                Divider().opacity(0.5)

                UsageEventView(events: self.session.snapshot?.usageEvents ?? [])
                
                if let modelsUsageChart = self.session.snapshot?.modelsUsageChart {
                    Divider().opacity(0.5)
                    
                    ModelsUsageBarChartView(data: modelsUsageChart)
                }

                Divider().opacity(0.5)

                totalCreditsUsageView
                
                Divider().opacity(0.5)

                MenuFooterView()
            } else {
                loginButtonView
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
        Button {
            loginWindow.show(onCookieCaptured: { cookie in
                Task {
                    guard let me = try? await self.service.fetchMe(cookieHeader: cookie) else { return }
                    try? await self.storage.saveCredentials(me)
                    await self.refresher.start()
                    self.session.credentials = me
                    self.session.snapshot = await self.storage.loadDashboardSnapshot()
                }
            })
        } label: {
            Text("Login to Cursor")
        }
        .buttonStyle(.vibe(.primary))
        .maxFrame(true, false)
    }

    private var totalCreditsUsageView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Credits Usage")
                .font(.app(.satoshiRegular, size: 12))
                .foregroundStyle(.secondary)

            Text(session.snapshot?.totalUsageCents.dollarStringFromCents ?? "0")
                .font(.app(.satoshiBold, size: 16))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                
        }
        .maxFrame(true, false, alignment: .leading)
    }
    
    private func setLoggedOut() async {
        await self.storage.clearCredentials()
        await self.storage.clearDashboardSnapshot()
        self.session.credentials = nil
        self.session.snapshot = nil
    }

    private func openDashboard() {
        NSWorkspace.shared.open(URL(string: "https://cursor.com/dashboard?tab=usage")!)
    }
}
