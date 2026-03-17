import Flutter
import UIKit

public final class GraceWindowIosPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static let methodChannelName = "io.ente.photos.grace_window_ios/methods"
  private static let eventChannelName = "io.ente.photos.grace_window_ios/events"

  private var eventSink: FlutterEventSink?
  private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = GraceWindowIosPlugin()
    let methodChannel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: registrar.messenger()
    )

    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
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
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func beginGraceWindow(name: String) {
    endGraceWindow()
    backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
      self?.eventSink?(true)
      self?.endGraceWindow()
    }
  }

  private func endGraceWindow() {
    guard backgroundTaskID != .invalid else {
      return
    }

    UIApplication.shared.endBackgroundTask(backgroundTaskID)
    backgroundTaskID = .invalid
  }
}
