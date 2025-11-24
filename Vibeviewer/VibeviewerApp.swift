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
    @State private var loginService: any LoginService = NoopLoginService()
    @State private var updateService: any UpdateService = {
        // 从 Info.plist 读取 appcast URL，如果没有则使用默认值
        let feedURLString = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String
            ?? "https://raw.githubusercontent.com/MarveleE/Vibeviewer/refs/heads/feat/auto-update/appcast.xml"
        
        if let feedURL = URL(string: feedURLString) {
            return SparkleUpdateService(feedURL: feedURL)
        } else {
            return NoopUpdateService()
        }
    }()

    var body: some Scene {
        MenuBarExtra {
            MenuPopoverView()
                .environment(\.cursorService, DefaultCursorService())
                .environment(\.cursorStorage, DefaultCursorStorageService())
                .environment(\.loginWindowManager, LoginWindowManager.shared)
                .environment(\.settingsWindowManager, SettingsWindowManager.shared)
                .environment(\.dashboardRefreshService, self.refresher)
                .environment(\.loginService, self.loginService)
                .environment(\.launchAtLoginService, DefaultLaunchAtLoginService())
                .environment(\.updateService, self.updateService)
                .environment(self.settings)
                .environment(self.session)
                .menuBarExtraWindowCorner()
                .onAppear {
                    SettingsWindowManager.shared.appSettings = self.settings
                    SettingsWindowManager.shared.appSession = self.session
                    SettingsWindowManager.shared.dashboardRefreshService = self.refresher
                    SettingsWindowManager.shared.updateService = self.updateService
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
            Image(.menuBarIcon)
                .renderingMode(.template)
                .resizable()
                .frame(width: 16, height: 16)
                .padding(.trailing, 4)
                .foregroundStyle(.primary)
            Text({
                guard let snapshot = self.session.snapshot else { return "" }
                return snapshot.displayTotalUsageCents.dollarStringFromCents
            }())
                .font(.app(.satoshiBold, size: 15))
                .foregroundColor(.primary)
        }
        .task {
            await self.setupDashboardRefreshService()
        }
    }

    private func setupDashboardRefreshService() async {
        let api = DefaultCursorService()
        let storage = DefaultCursorStorageService()
        
        let dashboardRefreshSvc = DefaultDashboardRefreshService(
            api: api,
            storage: storage,
            settings: self.settings,
            session: self.session
        )
        let screenPowerSvc = DefaultScreenPowerStateService()
        let powerAwareSvc = PowerAwareDashboardRefreshService(
            refreshService: dashboardRefreshSvc,
            screenPowerService: screenPowerSvc
        )
        self.refresher = powerAwareSvc
        
        // 创建登录服务，依赖刷新服务
        self.loginService = DefaultLoginService(
            api: api,
            storage: storage,
            refresher: self.refresher,
            session: self.session
        )
        
        await self.refresher.start()
        
        // 启动时自动检查更新（后台）
        await self.updateService.checkForUpdatesInBackground()
    }
}

