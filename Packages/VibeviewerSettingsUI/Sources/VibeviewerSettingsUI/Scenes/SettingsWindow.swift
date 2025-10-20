import AppKit
import SwiftUI
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

    public func show() {
        if let controller {
            controller.close()
            self.controller = nil
        }
        let vc = NSHostingController(rootView: SettingsView()
            .environment(self.appSettings)
            .environment(self.appSession))
        let window = NSWindow(contentViewController: vc)
        window.title = "Settings"
        window.setContentSize(NSSize(width: 320, height: 240))
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        let ctrl = NSWindowController(window: window)
        self.controller = ctrl
        ctrl.window?.center()
        ctrl.showWindow(nil)
        ctrl.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func close() {
        self.controller?.close()
        self.controller = nil
    }
}
