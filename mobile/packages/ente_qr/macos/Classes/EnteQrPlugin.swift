import Cocoa
import CoreGraphics
import CoreVideo
import FlutterMacOS
import ScreenCaptureKit
import Vision

public class EnteQrPlugin: NSObject, FlutterPlugin {
  private static let detectionQueue = DispatchQueue(label: "io.ente.qr.detection", qos: .userInitiated)

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ente_qr", binaryMessenger: registrar.messenger)
    let instance = EnteQrPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "scanQrFromImage":
      guard let imagePath = imagePath(from: call.arguments) else {
        result([
          "success": false,
          "error": "Image path is required",
        ])
        return
      }

      scanQrCode(from: imagePath, result: result)
    case "scanQrFromCurrentWindow":
      scanQrCodeFromCurrentWindow(result: result)
    case "scanAllQrFromImage":
      guard let imagePath = imagePath(from: call.arguments) else {
        result([
          "success": false,
          "error": "Image path is required",
        ])
        return
      }

      scanAllQrCodes(from: imagePath, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func imagePath(from arguments: Any?) -> String? {
    guard let args = arguments as? [String: Any] else {
      return nil
    }
    return args["imagePath"] as? String
  }

  private func scanQrCode(from imagePath: String, result: @escaping FlutterResult) {
    detectQrCodes(from: imagePath) { detectionResult in
      switch detectionResult {
      case .success(let detections):
        guard let content = detections.first?["content"] as? String else {
          result([
            "success": false,
            "error": "No QR code found in image",
          ])
          return
        }
        result([
          "success": true,
          "content": content,
        ])
      case .failure(let error):
        result([
          "success": false,
          "error": error.localizedDescription,
        ])
      }
    }
  }

  private func scanQrCodeFromCurrentWindow(result: @escaping FlutterResult) {
    if #available(macOS 10.15, *) {
      guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
        result([
          "success": false,
          "error": EnteQrError.screenCapturePermissionRequired.localizedDescription,
        ])
        return
      }
    }

    guard let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) else {
      result([
        "success": false,
        "error": EnteQrError.currentWindowUnavailable.localizedDescription,
      ])
      return
    }

    let windowID = CGWindowID(window.windowNumber)
    if #available(macOS 14.0, *) {
      scanQrCodeWithScreenCaptureKit(windowID: windowID, result: result)
    } else {
      scanQrCodeWithCoreGraphics(windowID: windowID, result: result)
    }
  }

  @available(macOS 14.0, *)
  private func scanQrCodeWithScreenCaptureKit(
    windowID: CGWindowID,
    result: @escaping FlutterResult
  ) {
    SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true) { content, error in
      if let error {
        self.finishWithError(result, error.localizedDescription)
        return
      }

      guard let content,
            let currentWindow = content.windows.first(where: { $0.windowID == windowID }) else {
        self.finishWithError(result, EnteQrError.currentWindowUnavailable.localizedDescription)
        return
      }

      guard let display = self.display(containing: currentWindow.frame, in: content.displays) else {
        self.finishWithError(result, EnteQrError.displayUnavailable.localizedDescription)
        return
      }

      let captureFrame = currentWindow.frame.intersection(display.frame)
      guard !captureFrame.isEmpty else {
        self.finishWithError(result, EnteQrError.currentWindowBoundsUnavailable.localizedDescription)
        return
      }

      let sourceRect = CGRect(
        x: captureFrame.minX - display.frame.minX,
        y: captureFrame.minY - display.frame.minY,
        width: captureFrame.width,
        height: captureFrame.height
      )
      let scale = self.backingScaleFactor(for: display.displayID) ?? CGFloat(
        SCContentFilter(display: display, excludingWindows: [currentWindow]).pointPixelScale
      )

      let filter = SCContentFilter(display: display, excludingWindows: [currentWindow])
      let configuration = SCStreamConfiguration()
      configuration.sourceRect = sourceRect
      configuration.width = max(1, Int(sourceRect.width * scale))
      configuration.height = max(1, Int(sourceRect.height * scale))
      configuration.pixelFormat = kCVPixelFormatType_32BGRA
      configuration.showsCursor = false
      configuration.shouldBeOpaque = true

      SCScreenshotManager.captureImage(
        contentFilter: filter,
        configuration: configuration
      ) { image, error in
        if let error {
          self.finishWithError(result, error.localizedDescription)
          return
        }
        guard let image else {
          self.finishWithError(result, EnteQrError.unableToCaptureScreen.localizedDescription)
          return
        }
        self.scanQrCode(from: image, result: result)
      }
    }
  }

  @available(macOS, introduced: 10.0, obsoleted: 15.0)
  private func scanQrCodeWithCoreGraphics(
    windowID: CGWindowID,
    result: @escaping FlutterResult
  ) {
    guard let captureBounds = captureBounds(for: windowID), !captureBounds.isEmpty else {
      result([
        "success": false,
        "error": EnteQrError.currentWindowBoundsUnavailable.localizedDescription,
      ])
      return
    }

    guard let cgImage = CGWindowListCreateImage(
      captureBounds,
      .optionOnScreenBelowWindow,
      windowID,
      [.bestResolution]
    ) else {
      result([
        "success": false,
        "error": EnteQrError.unableToCaptureScreen.localizedDescription,
      ])
      return
    }

    scanQrCode(from: cgImage, result: result)
  }

  private func scanQrCode(from cgImage: CGImage, result: @escaping FlutterResult) {
    detectQrCodes(in: cgImage) { detectionResult in
      switch detectionResult {
      case .success(let detections):
        guard let content = detections.first?["content"] as? String else {
          result([
            "success": false,
            "error": "No QR code found on screen",
          ])
          return
        }
        result([
          "success": true,
          "content": content,
        ])
      case .failure(let error):
        result([
          "success": false,
          "error": error.localizedDescription,
        ])
      }
    }
  }

  private func scanAllQrCodes(from imagePath: String, result: @escaping FlutterResult) {
    detectQrCodes(from: imagePath) { detectionResult in
      switch detectionResult {
      case .success(let detections):
        result([
          "success": true,
          "detections": detections,
        ])
      case .failure(let error):
        result([
          "success": false,
          "error": error.localizedDescription,
        ])
      }
    }
  }

  private func detectQrCodes(
    from imagePath: String,
    completion: @escaping (Result<[[String: Any]], Error>) -> Void
  ) {
    EnteQrPlugin.detectionQueue.async {
      do {
        let cgImage = try self.loadCgImage(from: imagePath)
        self.detectQrCodes(in: cgImage, completion: completion)
      } catch {
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }
  }

  private func detectQrCodes(
    in cgImage: CGImage,
    completion: @escaping (Result<[[String: Any]], Error>) -> Void
  ) {
    EnteQrPlugin.detectionQueue.async {
      do {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        let detections = observations.compactMap { observation -> [String: Any]? in
          guard observation.symbology == .qr,
                let payload = observation.payloadStringValue,
                !payload.isEmpty else {
            return nil
          }

          let box = observation.boundingBox
          return [
            "content": payload,
            "x": Double(box.minX),
            "y": Double(1.0 - box.maxY),
            "width": Double(box.width),
            "height": Double(box.height),
          ]
        }

        DispatchQueue.main.async {
          if detections.isEmpty {
            completion(.failure(EnteQrError.noQrCodeFound))
          } else {
            completion(.success(detections))
          }
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }
  }

  private func captureBounds(for windowID: CGWindowID) -> CGRect? {
    guard let windowInfo = CGWindowListCopyWindowInfo(
      [.optionIncludingWindow],
      windowID
    ) as? [[String: Any]],
      let boundsDictionary = windowInfo.first?[kCGWindowBounds as String] as? [String: Any] else {
      return nil
    }

    var bounds = CGRect.zero
    guard CGRectMakeWithDictionaryRepresentation(boundsDictionary as CFDictionary, &bounds) else {
      return nil
    }
    return bounds
  }

  @available(macOS 14.0, *)
  private func display(containing frame: CGRect, in displays: [SCDisplay]) -> SCDisplay? {
    displays
      .map { display in
        (display: display, area: area(display.frame.intersection(frame)))
      }
      .max { lhs, rhs in lhs.area < rhs.area }?
      .display
  }

  private func backingScaleFactor(for displayID: CGDirectDisplayID) -> CGFloat? {
    NSScreen.screens.first { screen in
      let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
      return screenNumber?.uint32Value == displayID
    }?.backingScaleFactor
  }

  private func area(_ rect: CGRect) -> CGFloat {
    if rect.isEmpty {
      return 0
    }
    return rect.width * rect.height
  }

  private func finishWithError(_ result: @escaping FlutterResult, _ message: String) {
    DispatchQueue.main.async {
      result([
        "success": false,
        "error": message,
      ])
    }
  }

  private func loadCgImage(from imagePath: String) throws -> CGImage {
    guard let image = NSImage(contentsOfFile: imagePath) else {
      throw EnteQrError.unableToLoadImage
    }

    var proposedRect = NSRect(origin: .zero, size: image.size)
    guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
      throw EnteQrError.unableToCreateCgImage
    }
    return cgImage
  }
}

private enum EnteQrError: LocalizedError {
  case unableToLoadImage
  case unableToCreateCgImage
  case noQrCodeFound
  case screenCapturePermissionRequired
  case currentWindowUnavailable
  case currentWindowBoundsUnavailable
  case displayUnavailable
  case unableToCaptureScreen

  var errorDescription: String? {
    switch self {
    case .unableToLoadImage:
      return "Unable to load image from path"
    case .unableToCreateCgImage:
      return "Unable to create CGImage from image"
    case .noQrCodeFound:
      return "No QR code found in image"
    case .screenCapturePermissionRequired:
      return "Screen Recording permission is required. Allow Ente Auth in System Settings and try again."
    case .currentWindowUnavailable:
      return "Unable to find the current app window"
    case .currentWindowBoundsUnavailable:
      return "Unable to read the current app window bounds"
    case .displayUnavailable:
      return "Unable to find the display containing the current app window"
    case .unableToCaptureScreen:
      return "Unable to capture the screen area behind the current app window"
    }
  }
}
