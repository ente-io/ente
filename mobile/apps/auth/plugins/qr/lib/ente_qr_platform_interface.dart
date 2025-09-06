import 'package:ente_qr/ente_qr_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The result of QR code scanning
class QrScanResult {
  final String? content;
  final String? error;
  final bool success;

  const QrScanResult({
    this.content,
    this.error,
    required this.success,
  });

  factory QrScanResult.success(String content) {
    return QrScanResult(
      content: content,
      success: true,
    );
  }

  factory QrScanResult.error(String error) {
    return QrScanResult(
      error: error,
      success: false,
    );
  }
}

abstract class EnteQrPlatform extends PlatformInterface {
  /// Constructs a EnteQrPlatform.
  EnteQrPlatform() : super(token: _token);

  static final Object _token = Object();

  static EnteQrPlatform _instance = MethodChannelEnteQr();

  /// The default instance of [EnteQrPlatform] to use.
  ///
  /// Defaults to [MethodChannelEnteQr].
  static EnteQrPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EnteQrPlatform] when
  /// they register themselves.
  static set instance(EnteQrPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Scans a QR code from an image file at the given path.
  /// Returns the QR code content as a string if successful, null otherwise.
  Future<QrScanResult> scanQrFromImage(String imagePath) {
    throw UnimplementedError('scanQrFromImage() has not been implemented.');
  }
}
