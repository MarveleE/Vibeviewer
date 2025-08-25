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
    
    @State private var session: VibeviewerModel.AppSession = VibeviewerModel.AppSession(
        credentials: DefaultCursorStorageService.loadCredentialsSync(),
        snapshot: DefaultCursorStorageService.loadDashboardSnapshotSync()
    )

    var body: some Scene {
        MenuBarExtra(isInserted: .constant(true)) {
            MenuPopoverView()
                .environment(\.cursorService, DefaultCursorService())
                .environment(\.cursorStorage, DefaultCursorStorageService())
                .environment(\.loginWindowManager, LoginWindowManager.shared)
                .environment(\.settingsWindowManager, SettingsWindowManager.shared)
                .environment(settings)
                .environment(session)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(.trailing, 4)
                Text(session.snapshot?.spendingCents.dollarStringFromCents ?? "Vibeviewer")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
    }
}
