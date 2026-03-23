import Flutter
import UIKit

public final class GraceWindowIosPlugin: NSObject, FlutterPlugin {
  private static let methodChannelName = "io.ente.photos.grace_window_ios/methods"
  private static let expiredStateDefaultsKey = "io.ente.photos.grace_window_ios.expired"

  private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
  private var pendingExpirationResult: FlutterResult?
  private var bufferedExpiration: Bool?
  private var didExpire = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = GraceWindowIosPlugin()
    let methodChannel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "beginGraceWindow":
      let arguments = call.arguments as? [String: Any]
      let name = arguments?["name"] as? String ?? "upload-grace-window"
      beginGraceWindow(name: name)
      result(nil)
    case "endGraceWindow":
      endGraceWindow()
      result(nil)
    case "awaitExpiration":
      if let buffered = bufferedExpiration {
        bufferedExpiration = nil
        result(buffered)
      } else {
        pendingExpirationResult = result
      }
    case "consumeExpiredGraceWindowState":
      result(consumeExpiredGraceWindowState())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func beginGraceWindow(name: String) {
    endGraceWindow()
    didExpire = false
    bufferedExpiration = nil
    UserDefaults.standard.set(false, forKey: Self.expiredStateDefaultsKey)
    backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
      UserDefaults.standard.set(true, forKey: Self.expiredStateDefaultsKey)
      self?.didExpire = true
      self?.resolveAwait(expired: true)
      self?.terminateBackgroundTask()
    }
  }

  private func resolveAwait(expired: Bool) {
    if let pending = pendingExpirationResult {
      pending(expired)
      pendingExpirationResult = nil
    } else {
      bufferedExpiration = expired
    }
  }

  private func consumeExpiredGraceWindowState() -> Bool {
    let defaults = UserDefaults.standard
    let didExpire = defaults.bool(forKey: Self.expiredStateDefaultsKey)
    defaults.set(false, forKey: Self.expiredStateDefaultsKey)
    return didExpire
  }

  /// Called from Dart when the grace window is no longer needed.
  /// Only resolves the pending await with false if no expiration occurred.
  private func endGraceWindow() {
    if !didExpire {
      resolveAwait(expired: false)
    }
    terminateBackgroundTask()
  }

  private func terminateBackgroundTask() {
    guard backgroundTaskID != .invalid else {
      return
    }
    UIApplication.shared.endBackgroundTask(backgroundTaskID)
    backgroundTaskID = .invalid
  }
}
