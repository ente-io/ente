import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    var flutter_native_splash = 1
    UIApplication.shared.isStatusBarHidden = false

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

   override func applicationDidBecomeActive(_ application: UIApplication) {
       signal(SIGPIPE, SIG_IGN);
   }

   override func applicationWillEnterForeground(_ application: UIApplication) {
       signal(SIGPIPE, SIG_IGN);
   }
}