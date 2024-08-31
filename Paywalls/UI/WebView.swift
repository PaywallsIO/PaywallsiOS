import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    let navigationDelegate: WKNavigationDelegate?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        if let navigationDelegate {
            webView.navigationDelegate = navigationDelegate
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
