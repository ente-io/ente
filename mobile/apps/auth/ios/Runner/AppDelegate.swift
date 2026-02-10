#if canImport(Flutter)
import Flutter
import UIKit
#if canImport(app_links)
import app_links
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    super.application(application, didFinishLaunchingWithOptions: launchOptions)

#if canImport(app_links)
    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      AppLinks.shared.handleLink(url: url)
    }
#endif

    return false

    // return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
#else
import UIKit

@main
@objc class AppDelegate: UIResponder, UIApplicationDelegate {}
#endif
