//
//  VibeviewerApp.swift
//  Vibeviewer
//
//  Created by Groot chen on 2025/8/24.
//

import Observation
import SwiftUI
import VibeviewerAPI
import VibeviewerAppEnvironment
import VibeviewerCore
import VibeviewerLoginUI
import VibeviewerMenuUI
import VibeviewerModel
import VibeviewerSettingsUI
import VibeviewerStorage
import VibeviewerShareUI

@main
struct VibeviewerApp: App {
    @State private var settings: AppSettings = DefaultCursorStorageService.loadSettingsSync()

    @State private var session: VibeviewerModel.AppSession = .init(
        credentials: DefaultCursorStorageService.loadCredentialsSync(),
        snapshot: DefaultCursorStorageService.loadDashboardSnapshotSync()
    )
    @State private var refresher: any DashboardRefreshService = NoopDashboardRefreshService()

    var body: some Scene {
        MenuBarExtra {
            MenuPopoverView()
                .environment(\.cursorService, DefaultCursorService())
                .environment(\.cursorStorage, DefaultCursorStorageService())
                .environment(\.loginWindowManager, LoginWindowManager.shared)
                .environment(\.settingsWindowManager, SettingsWindowManager.shared)
                .environment(\.dashboardRefreshService, self.refresher)
                .environment(\.launchAtLoginService, DefaultLaunchAtLoginService())
                .environment(self.settings)
                .environment(self.session)
                .menuBarExtraWindowCorner()
                .onAppear {
                    SettingsWindowManager.shared.appSettings = self.settings
                }
                .id(self.settings.appearance)
                .applyPreferredColorScheme(self.settings.appearance)
        } label: {
            menuBarLabel()
        }
        .menuBarExtraStyle(.window)
        .windowResizability(.contentSize)
    }

    private func menuBarLabel() -> some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .resizable()
                .frame(width: 16, height: 16)
                .padding(.trailing, 4)
            Text({
                guard let snapshot = self.session.snapshot else { return "Vibeviewer" }
                
                if let usageSummary = snapshot.usageSummary {
                    let planUsed = usageSummary.individualUsage.plan.used
                    let onDemandUsed = usageSummary.individualUsage.onDemand?.used ?? 0
                    let totalUsageCents = planUsed + onDemandUsed
                    return totalUsageCents.dollarStringFromCents
                } else {
                    return snapshot.spendingCents.dollarStringFromCents
                }
            }())
                .font(.app(.satoshiBold, size: 15))
                .foregroundColor(.primary)
        }
        .task {
            await self.setupDashboardRefreshService()
        }
    }

    private func setupDashboardRefreshService() async {
        let dashboardRefreshSvc = DefaultDashboardRefreshService(
            api: DefaultCursorService(),
            storage: DefaultCursorStorageService(),
            settings: self.settings,
            session: self.session
        )
        let screenPowerSvc = DefaultScreenPowerStateService()
        let powerAwareSvc = PowerAwareDashboardRefreshService(
            refreshService: dashboardRefreshSvc,
            screenPowerService: screenPowerSvc
        )
        self.refresher = powerAwareSvc
        await self.refresher.start()
    }
}

