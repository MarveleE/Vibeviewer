import SwiftUI
import WebKit

struct CookieWebView: NSViewRepresentable {
    let onCookieCaptured: (String) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        if let url =
            URL(
                string: "https://authenticator.cursor.sh/"
            )
        {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCookieCaptured: self.onCookieCaptured)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let onCookieCaptured: (String) -> Void

        init(onCookieCaptured: @escaping (String) -> Void) {
            self.onCookieCaptured = onCookieCaptured
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if webView.url?.absoluteString.hasSuffix("/dashboard") == true {
                self.captureCursorCookies(from: webView)
            }
        }

        private func captureCursorCookies(from webView: WKWebView) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                let relevant = cookies.filter { cookie in
                    let domain = cookie.domain.lowercased()
                    return domain.contains("cursor.com")
                }
                guard !relevant.isEmpty else { return }
                let headerString = relevant.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
                self.onCookieCaptured(headerString)
            }
        }
    }
}
