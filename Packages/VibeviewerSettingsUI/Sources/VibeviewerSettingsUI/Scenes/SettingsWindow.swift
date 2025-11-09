import AppKit
import SwiftUI
import VibeviewerAppEnvironment
import VibeviewerCore
import VibeviewerModel
import VibeviewerStorage

@MainActor
public final class SettingsWindowManager {
    public static let shared = SettingsWindowManager()
    private var controller: NSWindowController?
    public var appSettings: AppSettings = DefaultCursorStorageService.loadSettingsSync()
    public var appSession: AppSession = AppSession(
        credentials: DefaultCursorStorageService.loadCredentialsSync(),
        snapshot: DefaultCursorStorageService.loadDashboardSnapshotSync()
    )
    public var dashboardRefreshService: any DashboardRefreshService = NoopDashboardRefreshService()

    public func show() {
        // Close MenuBarExtra popover window if it's open
        closeMenuBarExtraWindow()
        
        if let controller {
            controller.close()
            self.controller = nil
        }
        let vc = NSHostingController(rootView: SettingsView()
            .environment(self.appSettings)
            .environment(self.appSession)
            .environment(\.dashboardRefreshService, self.dashboardRefreshService)
            .environment(\.cursorStorage, DefaultCursorStorageService())
            .environment(\.launchAtLoginService, DefaultLaunchAtLoginService()))
        let window = NSWindow(contentViewController: vc)
        window.title = "Settings"
        window.setContentSize(NSSize(width: 560, height: 500))
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = false
        window.toolbarStyle = .unified
        let ctrl = NSWindowController(window: window)
        self.controller = ctrl
        ctrl.window?.center()
        ctrl.showWindow(nil)
        ctrl.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func closeMenuBarExtraWindow() {
        // Close MenuBarExtra popover windows
        // MenuBarExtra windows are typically non-activating NSPanel instances
        for window in NSApp.windows {
            if let panel = window as? NSPanel,
               panel.styleMask.contains(.nonactivatingPanel),
               window != self.controller?.window {
                window.close()
            }
        }
    }

    public func close() {
        self.controller?.close()
        self.controller = nil
    }
}
