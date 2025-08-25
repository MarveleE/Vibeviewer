import SwiftUI

@MainActor
struct CursorLoginView: View {
    let onCookieCaptured: (String) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("登录 Cursor").font(.headline)
                Spacer()
                Button("关闭") { self.onClose() }
            }
            .padding(8)

            CookieWebView(onCookieCaptured: { cookie in
                self.onCookieCaptured(cookie)
                self.onClose()
            })
        }
    }
}

// CookieWebView 已拆分到 CookieWebView.swift
