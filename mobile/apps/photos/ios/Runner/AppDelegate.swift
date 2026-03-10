import AVFoundation
import Flutter
import UIKit
import app_links
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    WorkmanagerDebug.setCurrent(InternalUserWorkmanagerDebugHandler())

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

private final class InternalUserWorkmanagerDebugHandler: WorkmanagerDebug {
  private let delegate = NotificationDebugHandler()

  override func onTaskStatusUpdate(taskInfo: TaskDebugInfo, status: TaskStatus, result: TaskResult?) {
    guard shouldEnableWorkmanagerDebugNotifications() else { return }
    delegate.onTaskStatusUpdate(taskInfo: taskInfo, status: status, result: result)
  }

  override func onExceptionEncountered(taskInfo: TaskDebugInfo?, exception: Error) {
    guard shouldEnableWorkmanagerDebugNotifications() else { return }
    delegate.onExceptionEncountered(taskInfo: taskInfo, exception: exception)
  }

  private func shouldEnableWorkmanagerDebugNotifications() -> Bool {
    let defaults = UserDefaults.standard
    if defaults.bool(forKey: "flutter.ls.internal_user_disabled") {
      return false
    }

    #if DEBUG
      return true
    #else
      guard let remoteFlags = defaults.string(forKey: "flutter.remote_flags"),
            let data = remoteFlags.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
      else {
        return false
      }

      return json["internalUser"] as? Bool ?? false
    #endif
  }
}
