import Flutter
import UIKit
import Vision

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

  private func detectBarcodes(in cgImage: CGImage) -> [VNBarcodeObservation] {
    let request = VNDetectBarcodesRequest()
    request.symbologies = [.qr]

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([request])
    } catch {
      return []
    }

    return request.results ?? []
  }

  private func scanQrCode(from imagePath: String, result: @escaping FlutterResult) {
    EnteQrPlugin.detectionQueue.async {
      guard let image = UIImage(contentsOfFile: imagePath),
            let cgImage = image.cgImage else {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "Unable to load image from path: \(imagePath)"
          ])
        }
        return
      }

      let observations = self.detectBarcodes(in: cgImage)

      if let obs = observations.first,
         let payload = obs.payloadStringValue {
        DispatchQueue.main.async {
          result([
            "success": true,
            "content": payload
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
      guard let image = UIImage(contentsOfFile: imagePath),
            let cgImage = image.cgImage else {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "Unable to load image from path: \(imagePath)"
          ])
        }
        return
      }

      let observations = self.detectBarcodes(in: cgImage)

      var detections: [[String: Any]] = []

      for obs in observations {
        guard let payload = obs.payloadStringValue else { continue }

        // Vision's boundingBox is normalized [0,1] with origin at bottom-left.
        // Convert to top-left origin (y-down) for Flutter.
        let box = obs.boundingBox
        detections.append([
          "content": payload,
          "x": Double(box.origin.x),
          "y": Double(1.0 - box.origin.y - box.height),
          "width": Double(box.width),
          "height": Double(box.height),
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
