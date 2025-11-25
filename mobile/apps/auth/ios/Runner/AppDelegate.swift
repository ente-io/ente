import Flutter
import UIKit
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register custom security bookmark plugin for persistent directory access
    if let registrar = self.registrar(forPlugin: "SecurityBookmarkPlugin") {
      SecurityBookmarkPlugin.register(with: registrar)
    }

    super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      AppLinks.shared.handleLink(url: url)
    }

    return false

    // return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
