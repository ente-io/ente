import Flutter
import UIKit

public class EnteQrPlugin: NSObject, FlutterPlugin {
  private static let detectionQueue = DispatchQueue(label: "io.ente.qr.detection", qos: .userInitiated)

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ente_qr", binaryMessenger: registrar.messenger())
    let instance = EnteQrPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "scanQrFromImage":
      guard let args = call.arguments as? [String: Any],
            let imagePath = args["imagePath"] as? String else {
        result([
          "success": false,
          "error": "Image path is required"
        ])
        return
      }

      scanQrCode(from: imagePath, result: result)
    case "scanAllQrFromImage":
      guard let args = call.arguments as? [String: Any],
            let imagePath = args["imagePath"] as? String else {
        result([
          "success": false,
          "error": "Image path is required"
        ])
        return
      }

      scanAllQrCodes(from: imagePath, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func scanQrCode(from imagePath: String, result: @escaping FlutterResult) {
    EnteQrPlugin.detectionQueue.async {
      guard let image = UIImage(contentsOfFile: imagePath) else {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "Unable to load image from path: \(imagePath)"
          ])
        }
        return
      }

      guard let cgImage = image.cgImage else {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "Unable to get CGImage from UIImage"
          ])
        }
        return
      }

      let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                               context: nil,
                               options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

      guard let qrDetector = detector else {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "Unable to create QR code detector"
          ])
        }
        return
      }

      let ciImage = CIImage(cgImage: cgImage)
      let features = qrDetector.features(in: ciImage)

      if let qrFeature = features.first as? CIQRCodeFeature,
         let messageString = qrFeature.messageString {
        DispatchQueue.main.async {
          result([
            "success": true,
            "content": messageString
          ])
        }
      } else {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "No QR code found in image"
          ])
        }
      }
    }
  }

  private func scanAllQrCodes(from imagePath: String, result: @escaping FlutterResult) {
    EnteQrPlugin.detectionQueue.async {
      guard let image = UIImage(contentsOfFile: imagePath) else {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "Unable to load image from path: \(imagePath)"
          ])
        }
        return
      }

      guard let cgImage = image.cgImage else {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "Unable to get CGImage from UIImage"
          ])
        }
        return
      }

      let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                               context: nil,
                               options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

      guard let qrDetector = detector else {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "Unable to create QR code detector"
          ])
        }
        return
      }

      let ciImage = CIImage(cgImage: cgImage)
      let features = qrDetector.features(in: ciImage)

      let imageWidth = CGFloat(cgImage.width)
      let imageHeight = CGFloat(cgImage.height)

      var detections: [[String: Any]] = []

      for feature in features {
        guard let qrFeature = feature as? CIQRCodeFeature,
              let messageString = qrFeature.messageString else {
          continue
        }

        // Core Image has origin at bottom-left with y-up.
        // Convert to normalized [0,1] coords with origin top-left, y-down.
        let minX = min(qrFeature.topLeft.x, qrFeature.bottomLeft.x)
        let maxX = max(qrFeature.topRight.x, qrFeature.bottomRight.x)
        // In CI coords, topLeft.y > bottomLeft.y (y goes up)
        let minYci = min(qrFeature.bottomLeft.y, qrFeature.bottomRight.y)
        let maxYci = max(qrFeature.topLeft.y, qrFeature.topRight.y)

        // Add padding around finder patterns (matching Android's 15%)
        let padX = (maxX - minX) * 0.15
        let padY = (maxYci - minYci) * 0.15
        let paddedMinX = max(minX - padX, 0)
        let paddedMaxX = min(maxX + padX, imageWidth)
        let paddedMinYci = max(minYci - padY, 0)
        let paddedMaxYci = min(maxYci + padY, imageHeight)

        // Flip y: top-left origin
        let normX = paddedMinX / imageWidth
        let normY = 1.0 - (paddedMaxYci / imageHeight)
        let normW = (paddedMaxX - paddedMinX) / imageWidth
        let normH = (paddedMaxYci - paddedMinYci) / imageHeight

        detections.append([
          "content": messageString,
          "x": Double(normX),
          "y": Double(normY),
          "width": Double(normW),
          "height": Double(normH),
        ])
      }

      if detections.isEmpty {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "No QR code found in image"
          ])
        }
      } else {
        DispatchQueue.main.async {
          result([
            "success": true,
            "detections": detections
          ])
        }
      }
    }
  }
}
