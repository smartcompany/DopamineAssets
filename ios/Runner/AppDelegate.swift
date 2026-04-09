import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("[UL][iOS] didFinishLaunching")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    let url = userActivity.webpageURL?.absoluteString ?? "nil"
    NSLog("[UL][iOS] continueUserActivity type=\(userActivity.activityType) url=\(url)")
    let handled = super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
    NSLog("[UL][iOS] continueUserActivity superHandled=\(handled)")

    // Universal Link가 앱에서 처리된 뒤에도 iOS가 웹으로 폴백하는 케이스를 방지한다.
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      NSLog("[UL][iOS] continueUserActivity force return true (browsing web)")
      return true
    }
    NSLog("[UL][iOS] continueUserActivity return handled=\(handled)")
    return handled
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    NSLog("[UL][iOS] openURL url=\(url.absoluteString)")
    let handled = super.application(app, open: url, options: options)
    NSLog("[UL][iOS] openURL superHandled=\(handled)")
    return handled
  }
}
