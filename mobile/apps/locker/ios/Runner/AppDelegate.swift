import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "LockerPdfMetadata") {
      FlutterMethodChannel(name: "io.ente.locker/pdf_metadata",
                           binaryMessenger: registrar.messenger()).setMethodCallHandler { call, result in
        guard call.method == "pageRatios", let path = call.arguments as? String else {
          result(FlutterMethodNotImplemented)
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          guard let document = CGPDFDocument(URL(fileURLWithPath: path) as CFURL),
                document.numberOfPages > 0 else {
            DispatchQueue.main.async {
              result(FlutterError(code: "invalid_pdf", message: "Cannot read PDF dimensions", details: nil))
            }
            return
          }
          let ratios = (1...document.numberOfPages).map { number -> Double in
            guard let page = document.page(at: number) else { return 0.75 }
            let size = page.getBoxRect(.mediaBox).size
            let ratio = Double(size.width / size.height)
            guard ratio.isFinite, ratio > 0 else { return 0.75 }
            // Match pdfx's bitmap orientation, including non-normalized rotations.
            return page.rotationAngle == 90 || page.rotationAngle == 270 ? 1 / ratio : ratio
          }
          DispatchQueue.main.async { result(ratios) }
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
