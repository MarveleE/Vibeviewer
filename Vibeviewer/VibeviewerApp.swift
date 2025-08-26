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
                .environment(self.settings)
                .environment(self.session)
                .background {
                    MenuBarExtraWindowHelperView()
                }
                
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(.trailing, 4)
                Text(self.session.snapshot?.spendingCents.dollarStringFromCents ?? "Vibeviewer")
                    .font(.app(.satoshiBold, size: 15))
                    .foregroundColor(.primary)
            }
            .task {
                // 启动后台刷新服务
                let svc = DefaultDashboardRefreshService(
                    api: DefaultCursorService(),
                    storage: DefaultCursorStorageService(),
                    settings: self.settings,
                    session: self.session
                )
                self.refresher = svc
                await self.refresher.start()
            }
        }
        .menuBarExtraStyle(.window)
        .windowResizability(.contentSize)
    }
}
