import AppKit
import SwiftUI
import VibeviewerModel
import VibeviewerStorage

public final class SettingsWindowManager {
    public static let shared = SettingsWindowManager()
    private var controller: NSWindowController?
    public var appSettings: AppSettings = DefaultCursorStorageService.loadSettingsSync()

    public func show() {
        if let controller {
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let vc = NSHostingController(rootView: SettingsView().environment(self.appSettings))
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
