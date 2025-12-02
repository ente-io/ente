import Flutter
import UIKit
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set window background to purple (#A75CFF) to prevent white flash
    self.window?.backgroundColor = UIColor(red: 167.0/255.0, green: 92.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    
    GeneratedPluginRegistrant.register(with: self)
    super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      AppLinks.shared.handleLink(url: url)
    }

    return false

    // return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
