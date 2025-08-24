import SwiftUI
import WebKit

@MainActor
struct CursorLoginView: View {
    let onCookieCaptured: (String) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("登录 Cursor").font(.headline)
                Spacer()
                Button("关闭") { onClose() }
            }
            .padding(8)

            CookieWebView(onCookieCaptured: { cookie in
                onCookieCaptured(cookie)
                onClose()
            })
        }
    }
}

struct CookieWebView: NSViewRepresentable {
    let onCookieCaptured: (String) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        // 打开 Cursor 认证页
        if let url = URL(string: "https://authenticator.cursor.sh/?client_id=client_01GS6W3C96KW4WRS6Z93JCE2RJ&redirect_uri=https%3A%2F%2Fcursor.com%2Fapi%2Fauth%2Fcallback&response_type=code&state=%257B%2522returnTo%2522%253A%2522%252Fdashboard%2522%252C%2522nonce%2522%253A%252208ddb34e-7f2f-479d-b255-634624a0576d%2522%257D&authorization_session_id=01K3E2YSQEZNYDR26YJZVQQM4Y") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCookieCaptured: onCookieCaptured)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let onCookieCaptured: (String) -> Void

        init(onCookieCaptured: @escaping (String) -> Void) {
            self.onCookieCaptured = onCookieCaptured
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 登录成功后会跳转到dashboard
            if webView.url?.absoluteString.hasSuffix("/dashboard") == true {
                captureCursorCookies(from: webView)
            }
        }

        private func captureCursorCookies(from webView: WKWebView) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                // 只抓取 cursor.com 相关 cookie
                let relevant = cookies.filter { cookie in
                    guard let domain = cookie.domain.lowercased() as String? else { return false }
                    return domain.contains("cursor.com")
                }
                guard !relevant.isEmpty else { return }
                let headerString = relevant.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
                self.onCookieCaptured(headerString)
            }
        }
    }
}


