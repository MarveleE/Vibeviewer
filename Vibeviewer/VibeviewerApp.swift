//
//  VibeviewerApp.swift
//  Vibeviewer
//
//  Created by Groot chen on 2025/8/24.
//

import SwiftUI
import Observation
import VibeviewerAPI
import VibeviewerAppEnvironment
import VibeviewerLoginUI
import VibeviewerMenuUI
import VibeviewerModel
import VibeviewerSettingsUI
import VibeviewerStorage

@main
struct VibeviewerApp: App {

    @State private var settings: AppSettings = DefaultCursorStorageService.loadSettingsSync()

    var body: some Scene {
        MenuBarExtra("Vibeviewer", systemImage: "bolt.fill") {
            // 预加载缓存，首次打开菜单即有数据展示
            let initialCreds = DefaultCursorStorageService.loadCredentialsSync()
            let initialSnapshot = DefaultCursorStorageService.loadDashboardSnapshotSync()
            MenuPopoverView(initialCredentials: initialCreds, initialSnapshot: initialSnapshot)
                .environment(\.cursorService, DefaultCursorService())
                .environment(\.cursorStorage, DefaultCursorStorageService())
                .environment(\.loginWindowManager, LoginWindowManager.shared)
                .environment(\.settingsWindowManager, SettingsWindowManager.shared)
                .environment(settings)
        }
    }
}
