import AVFoundation
import Flutter
import UIKit
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let audioSessionChannel = FlutterMethodChannel(
      name: "io.ente.frame/audio_session",
      binaryMessenger: controller.binaryMessenger)

    audioSessionChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "setAudioSessionCategory" {
        self.setAudioSessionCategory(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)

    // Retrieve the link from parameters
    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      // We have a link, propagate it to your Flutter app or not
      AppLinks.shared.handleLink(url: url)
      return true  // Returning true will stop the propagation to other packages
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setAudioSessionCategory(result: @escaping FlutterResult) {
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
      try AVAudioSession.sharedInstance().setActive(true)
      result(nil)
    } catch {
      result(
        FlutterError(
          code: "AUDIO_SESSION_ERROR",
          message: "Failed to set audio session category",
          details: error.localizedDescription))
    }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    signal(SIGPIPE, SIG_IGN)
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    signal(SIGPIPE, SIG_IGN)
  }
}
