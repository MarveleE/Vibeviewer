import SwiftUI

@MainActor
struct CursorLoginView: View {
    let onCookieCaptured: (String) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            CookieWebView(onCookieCaptured: { cookie in
                self.onCookieCaptured(cookie)
                self.onClose()
            })
        }
    }
}