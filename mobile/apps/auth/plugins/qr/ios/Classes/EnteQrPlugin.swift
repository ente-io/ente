import Flutter
import UIKit
import AVFoundation

public class EnteQrPlugin: NSObject, FlutterPlugin {
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
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func scanQrCode(from imagePath: String, result: @escaping FlutterResult) {
    guard let image = UIImage(contentsOfFile: imagePath) else {
      result([
        "success": false,
        "error": "Unable to load image from path: \(imagePath)"
      ])
      return
    }
    
    guard let cgImage = image.cgImage else {
      result([
        "success": false,
        "error": "Unable to get CGImage from UIImage"
      ])
      return
    }
    
    let detector = CIDetector(ofType: CIDetectorTypeQRCode, 
                             context: nil, 
                             options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    guard let qrDetector = detector else {
      result([
        "success": false,
        "error": "Unable to create QR code detector"
      ])
      return
    }
    
    let ciImage = CIImage(cgImage: cgImage)
    let features = qrDetector.features(in: ciImage)
    
    if let qrFeature = features.first as? CIQRCodeFeature,
       let messageString = qrFeature.messageString {
      result([
        "success": true,
        "content": messageString
      ])
    } else {
      result([
        "success": false,
        "error": "No QR code found in image"
      ])
    }
  }
}
