import AVFoundation
import Flutter
import UIKit
import app_links
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    var freqInMinutes = 30 * 60
    // Register a periodic task in iOS 13+
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "io.ente.frame.iOSBackgroundAppRefresh",
      frequency: NSNumber(value: freqInMinutes))

    // Retrieve the link from parameters
    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      // only accept non-homewidget urls for AppLinks
      if !url.absoluteString.contains("&homeWidget") {
        AppLinks.shared.handleLink(url: url)
        // link is handled, stop propagation
        return true
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    signal(SIGPIPE, SIG_IGN)
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    signal(SIGPIPE, SIG_IGN)
  }
}
