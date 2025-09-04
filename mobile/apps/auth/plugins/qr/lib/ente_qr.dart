import 'package:ente_qr/ente_qr_platform_interface.dart';

export 'ente_qr_platform_interface.dart' show QrScanResult;

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
  ///
  /// Example:
  /// ```dart
  /// final qr = EnteQr();
  /// final result = await qr.scanQrFromImage('/path/to/image.jpg');
  /// if (result.success) {
  ///   print('QR Code content: ${result.content}');
  /// } else {
  ///   print('Error: ${result.error}');
  /// }
  /// ```
  Future<QrScanResult> scanQrFromImage(String imagePath) {
    return EnteQrPlatform.instance.scanQrFromImage(imagePath);
  }
}
