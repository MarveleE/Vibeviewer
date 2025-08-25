//
//  VibeviewerApp.swift
//  Vibeviewer
//
//  Created by Groot chen on 2025/8/24.
//

import SwiftUI
import VibeviewerAPI
import VibeviewerAppEnvironment
import VibeviewerLoginUI
import VibeviewerMenuUI
import VibeviewerModel
import VibeviewerSettingsUI

@main
struct VibeviewerApp: App {
    var body: some Scene {
        MenuBarExtra("Vibeviewer", systemImage: "bolt.fill") {
            // 预加载缓存，首次打开菜单即有数据展示
            let initialCreds = CursorStorage.loadCredentialsSync()
            let initialSnapshot = CursorStorage.loadDashboardSnapshotSync()
            MenuPopoverView(initialCredentials: initialCreds, initialSnapshot: initialSnapshot)
                .environment(\.cursorService, DefaultCursorService())
                .environment(\.cursorStorage, CursorStorage.shared)
                .environment(\.loginWindowManager, LoginWindowManager.shared)
                .environment(\.settingsWindowManager, SettingsWindowManager.shared)
        }
    }
}
