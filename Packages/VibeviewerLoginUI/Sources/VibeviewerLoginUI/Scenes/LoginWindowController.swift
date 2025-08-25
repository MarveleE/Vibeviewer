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
