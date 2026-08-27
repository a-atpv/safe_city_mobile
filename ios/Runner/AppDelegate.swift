import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ── WKWebView background freeze (0x8badf00d prevention) ──────────────
    //
    // Suspend the JS engine when the app loses focus; resume when it returns.
    //
    // IMPORTANT: we do NOT inject timer-killing JS (clearInterval, etc.)
    // or call window.stop(). That destroys the payment page's internal
    // state — Robokassa's timers, event listeners, and XHR handlers die
    // and the page becomes unresponsive after returning from background.
    //
    // Instead we use two SYNCHRONOUS operations:
    //   • stopLoading()  — cancels pending navigations (not XHR/fetch)
    //   • javaScriptEnabled = false — pauses the JS engine entirely
    //
    // When JS is re-enabled on foreground, pending timers and handlers
    // resume from where they stopped.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Freeze / unfreeze WKWebViews

  @objc private func handleWillResignActive() {
    forEachWKWebView { webView in
      // Pause the JavaScript engine (synchronous property set). The engine
      // stops processing any tasks — timer callbacks, XHR handlers,
      // requestAnimationFrame — so nothing runs on the main thread and the
      // iOS watchdog has no reason to kill the process.
      // NOTE: We do NOT call webView.stopLoading() so in-flight 3DS redirects
      // or payment form submissions are not aborted when switching to SMS.
      webView.configuration.preferences.javaScriptEnabled = false
    }
  }

  @objc private func handleDidBecomeActive() {
    forEachWKWebView { webView in
      // Resume the JavaScript engine. Pending timers and event handlers
      // continue from where they were paused.
      webView.configuration.preferences.javaScriptEnabled = true
    }
  }

  // MARK: - WKWebView discovery

  private func forEachWKWebView(_ action: (WKWebView) -> Void) {
    for window in Self.collectAllWindows(delegate: self) {
      if let rootView = window.rootViewController?.view {
        Self.walkSubviews(of: rootView, action: action)
      }
    }
  }

  /// Collect all UIWindows — from connected scenes (scene-based apps) and
  /// from the FlutterAppDelegate's own `window` property (may differ).
  private static func collectAllWindows(delegate: FlutterAppDelegate) -> [UIWindow] {
    var windows: [UIWindow] = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }

    if let appWindow = delegate.window, !windows.contains(appWindow) {
      windows.append(appWindow)
    }

    return windows
  }

  /// Recursively walk the view hierarchy looking for WKWebView instances.
  private static func walkSubviews(of view: UIView, action: (WKWebView) -> Void) {
    if let webView = view as? WKWebView {
      action(webView)
    }
    for child in view.subviews {
      walkSubviews(of: child, action: action)
    }
  }
}
