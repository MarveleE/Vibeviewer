import AppKit
import SwiftUI

final class LoginWindowController: NSWindowController, NSWindowDelegate {
    private var onCookieCaptured: ((String) -> Void)?

    convenience init(onCookieCaptured: @escaping (String) -> Void) {
        let vc = NSHostingController(rootView: CursorLoginView(onCookieCaptured: { cookie in
            onCookieCaptured(cookie)
        }, onClose: {}))
        let window = NSWindow(contentViewController: vc)
        window.title = "Cursor 登录"
        window.setContentSize(NSSize(width: 900, height: 680))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        self.init(window: window)
        self.onCookieCaptured = onCookieCaptured
        self.window?.delegate = self
    }
}

public final class LoginWindowManager {
    public static let shared = LoginWindowManager()
    private var controller: LoginWindowController?

    public func show(onCookieCaptured: @escaping (String) -> Void) {
        if let controller {
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let controller = LoginWindowController(onCookieCaptured: { [weak self] cookie in
            onCookieCaptured(cookie)
            self?.close()
        })
        self.controller = controller
        controller.window?.center()
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        if let hosting = controller.contentViewController as? NSHostingController<CursorLoginView> {
            hosting.rootView = CursorLoginView(onCookieCaptured: { cookie in
                onCookieCaptured(cookie)
                self.close()
            }, onClose: { [weak self] in
                self?.close()
            })
        }
    }

    public func close() {
        self.controller?.close()
        self.controller = nil
    }
}
