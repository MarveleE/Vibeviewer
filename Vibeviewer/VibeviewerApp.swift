//
//  VibeviewerApp.swift
//  Vibeviewer
//
//  Created by Groot chen on 2025/8/24.
//

import SwiftUI
import VibeviewerMenuUI
import VibeviewerAPI
import VibeviewerModel
import VibeviewerLoginUI
import VibeviewerSettingsUI

@main
struct VibeviewerApp: App {
    var body: some Scene {
        MenuBarExtra("Vibeviewer", systemImage: "bolt.fill") {
            MenuPopoverView()
                .environment(\.cursorService, DefaultCursorService())
                .environment(\.cursorStorage, CursorStorage.shared)
                .environment(\.loginWindowManager, LoginWindowManager.shared)
                .environment(\.settingsWindowManager, SettingsWindowManager.shared)
        }
    }
}
