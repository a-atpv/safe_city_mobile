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
    // Swiping the app away on the card-entry form and coming back killed it:
    // the payment page keeps JS busy, and the watchdog kills a process that
    // takes too long to suspend. Stopping the JS engine on the way out gives
    // it nothing to be busy with.
    //
    // The pair is didEnterBackground/willEnterForeground, NOT
    // willResignActive/didBecomeActive. Resigning active is not backgrounding:
    // it fires for the notification banner carrying the 3DS code, Control
    // Center, an incoming call. Cutting JS on those kills the payment page in
    // the middle of a payment, which is exactly what the watchdog fix must not
    // do. The suspend deadline is tied to entering the background, so that is
    // the only place worth acting.
    //
    // We also do NOT inject timer-killing JS, call stopLoading(), or navigate
    // to about:blank. Any of those wipes the entered card details and breaks
    // 3DS; disabling the engine leaves the DOM, form state, and cookies alone.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleDidEnterBackground),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Freeze / unfreeze WKWebViews

  @objc private func handleDidEnterBackground() {
    forEachWKWebView { webView in
      // Synchronous property set, so it lands before the process suspends.
      // Deprecated since iOS 14 in favour of WKWebpagePreferences, but that
      // replacement is read at navigation time only — this is the one that
      // reaches the page already on screen.
      webView.configuration.preferences.javaScriptEnabled = false
    }
  }

  @objc private func handleWillEnterForeground() {
    forEachWKWebView { webView in
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
