import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    let isInteractive: Bool
    var enableAutoScroll: Bool = false

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.processPool = WKProcessPool()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        if !isInteractive {
            webView.isUserInteractionEnabled = false
            webView.scrollView.isScrollEnabled = false
        }
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        if uiView.url != url {
            uiView.load(request)
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if parent.enableAutoScroll {
                // Auto-scroll logic: scroll down by 1px every 50ms
                let js = """
                function startAutoScroll() {
                    let lastScrollTop = -1;
                    setInterval(function() {
                        window.scrollBy(0, 1);
                        // Check if we hit bottom (optional, functionality to loop or bounce could be added later)
                    }, 50);
                }
                startAutoScroll();
                """
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }
    }
}
