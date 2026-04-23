import 'package:ente_auth_qr/ente_qr_platform_interface.dart';

export 'ente_qr_platform_interface.dart'
    show QrDetection, QrScanResult, QrScanResults;

class EnteQr {
  Future<String?> getPlatformVersion() {
    return EnteQrPlatform.instance.getPlatformVersion();
  }

  /// Scans a QR code from an image file at the given path.
  ///
  /// [imagePath] - The file path to the image containing the QR code
  ///
  /// Returns a [QrScanResult] containing either the QR code content on success
  /// or an error message on failure.
  Future<QrScanResult> scanQrFromImage(String imagePath) {
    return EnteQrPlatform.instance.scanQrFromImage(imagePath);
  }

  /// Scans all QR codes from an image file at the given path.
  ///
  /// Returns a [QrScanResults] containing a list of [QrDetection] with
  /// content and normalized bounding boxes for each detected QR code.
  Future<QrScanResults> scanAllQrFromImage(String imagePath) {
    return EnteQrPlatform.instance.scanAllQrFromImage(imagePath);
  }
}
