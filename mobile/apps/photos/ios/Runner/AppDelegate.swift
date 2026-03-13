import AVFoundation
import Flutter
import UIKit
import app_links
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let backgroundAppRefreshIdentifier =
    "io.ente.frame.iOSBackgroundAppRefresh"
  private static let backgroundProcessingIdentifier =
    "io.ente.frame.iOSBackgroundProcessing"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Prevent interrupting background audio from other apps on launch
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .ambient,
        mode: .default,
        options: [.mixWithOthers]
      )
    } catch {
      print("Failed to configure initial audio session: \(error)")
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    let refreshFrequencyInSeconds = 15 * 60
    // Keep native task registration in AppDelegate; Dart owns actual scheduling.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: Self.backgroundAppRefreshIdentifier,
      frequency: NSNumber(value: refreshFrequencyInSeconds))
    WorkmanagerPlugin.registerBGProcessingTask(
      withIdentifier: Self.backgroundProcessingIdentifier)

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
